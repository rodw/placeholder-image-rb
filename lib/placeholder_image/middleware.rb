# frozen_string_literal: true

require "uri"
require "digest"

# Rack middleware that serves generated placeholder PNGs.
#
#   use PlaceholderImage::Middleware, path_prefix: "/placeholder"
#
# Examples:
#   GET /placeholder/300.png             -> 300x300, default colors
#   GET /placeholder/640x480.png         -> 640x480, default colors
#   GET /placeholder/300x200.png?bg=eee&fg=999 -> 300x200, specified colors
#
# No image gems required: PNGs are encoded with stdlib zlib.
module PlaceholderImage
  class BadRequest < StandardError; end

  # ------------------------------------------------------------- Middleware --
  class Middleware
    DEFAULTS = {
      path_prefix: "/placeholder",
      image_max_dim_px: 4_000,
      image_max_total_px: 4_000 * 4_000,
      http_header_cache_control: "public, max-age=31536000, immutable",
      cache_max_entries: 128,
      image_default_bg: [0xEE, 0xEE, 0xEE],
      image_default_fg: [0x99, 0x99, 0x99]
    }.freeze

    DIMENSION = /[1-9]\d*/

    # @param app [#call] the downstream Rack application.
    # @param options [Hash] configuration overrides merged over {DEFAULTS}.
    # @option options [String] :path_prefix ("/placeholder") URL prefix the middleware serves.
    # @option options [Integer] :image_max_dim_px (4000) maximum width or height, in pixels.
    # @option options [Integer] :image_max_total_px (16_000_000) maximum total pixel count.
    # @option options [String] :http_header_cache_control the +Cache-Control+ response header value.
    # @option options [Integer] :cache_max_entries (128) in-memory FIFO cache size; +0+ disables caching.
    # @option options [Array(Integer, Integer, Integer), String] :image_default_bg default background color.
    # @option options [Array(Integer, Integer, Integer), String] :image_default_fg default foreground color.
    def initialize(app, **options)
      @app     = app
      @options = DEFAULTS.merge(options)
      @cache   = {}
      @mutex   = Mutex.new

      path_prefix = Regexp.escape(@options[:path_prefix].chomp("/"))
      @owned = %r{\A#{path_prefix}(?:[./]|\z)}
      @route = %r{\A#{path_prefix}/(#{DIMENSION})(?:x(#{DIMENSION}))?\.png\z}
    end

    # Rack entry point. Serves a PNG for owned paths and delegates everything else downstream.
    #
    # @param env [Hash] the Rack environment.
    # @return [Array(Integer, Hash, Array)] a Rack response tuple.
    def call(env)
      return @app.call(env) unless @owned.match?(env["PATH_INFO"])
      return error(env["REQUEST_METHOD"], 405, "method not allowed") unless %w[GET HEAD].include?(env["REQUEST_METHOD"])

      spec = parse(env["PATH_INFO"], env["QUERY_STRING"].to_s)
      etag = etag_for(spec)
      return [304, cache_headers(etag), []] if fresh?(env, etag)

      img  = fetch(spec)
      body = env["REQUEST_METHOD"] == "HEAD" ? [] : [img]

      [200, cache_headers(etag).merge(
        "content-type" => "image/png",
        "content-length" => img.bytesize.to_s
      ), body]
    rescue BadRequest => e
      error(env["REQUEST_METHOD"], 400, e.message)
    end

    private

    def cache_headers(etag)
      { "etag" => etag,
        "cache-control" => @options[:http_header_cache_control] }
    end

    def fresh?(env, etag)
      env["HTTP_IF_NONE_MATCH"].to_s.split(",").map(&:strip).include?(etag)
    end

    def etag_for(spec)
      %("#{Digest::SHA256.hexdigest(spec.inspect)[0, 16]}")
    end

    def error(req_method, status, message)
      body = req_method == "HEAD" ? "" : "#{message}\n"

      [
        status,
        { "content-type" => "text/plain; charset=utf-8",
          "content-length" => body.bytesize.to_s },
        [body]
      ]
    end

    def fetch(spec)
      @mutex.synchronize { return @cache[spec] if @cache.key?(spec) }

      img = Renderer.call(**spec)

      @mutex.synchronize do
        @cache[spec] = img if @options[:cache_max_entries].positive?
        @cache.shift while @cache.size > @options[:cache_max_entries] # FIFO eviction
      end

      img
    end

    def parse(path, query)
      width, height = parse_dimensions(path)
      params = parse_query_string(query)

      { width: width,
        height: height,
        bg: parse_color(params["bg"], @options[:image_default_bg]),
        fg: parse_color(params["fg"], @options[:image_default_fg]),
        text: "#{width}x#{height}" }
    end

    def parse_dimensions(path)
      match = @route.match(path) or
        raise BadRequest, "no such image; expected #{@options[:path_prefix]}/<SIZE>.png or " \
                          "#{@options[:path_prefix]}/<W>x<H>.png"

      width  = match[1].to_i
      height = (match[2] || match[1]).to_i
      max    = @options[:image_max_dim_px]

      raise BadRequest, "dimensions must be between 1 and #{max}" if width > max || height > max
      raise BadRequest, "image exceeds #{@options[:image_max_total_px]} pixels" if
        width * height > @options[:image_max_total_px]

      [width, height]
    end

    def parse_query_string(query)
      return {} if query.empty?

      URI.decode_www_form(query).to_h
    rescue ArgumentError
      raise BadRequest, "malformed query string"
    end

    def parse_color(value, default)
      value = default if value.nil? || value.empty?
      return value if value.is_a?(Array)

      hex = value.delete_prefix("#")
      hex = hex.chars.map { |c| c * 2 }.join if hex.length == 3
      raise BadRequest, "invalid color: #{value}" unless hex.match?(/\A\h{6}\z/)

      [hex[0, 2], hex[2, 2], hex[4, 2]].map { |pair| pair.to_i(16) }
    end
  end
end
