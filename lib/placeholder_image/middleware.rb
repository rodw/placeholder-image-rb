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
# Only requests beginning with "<path_prefix>/" are handled; everything else
# (including the bare prefix and sibling paths such as "/placeholder.css") is
# passed through to the downstream application.
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

    # Maximum length of a client-supplied value echoed back in an error message.
    ERROR_VALUE_MAX_LENGTH = 32

    # @param app [#call] the downstream Rack application.
    # @param options [Hash] configuration overrides merged over {DEFAULTS}.
    # @option options [String] :path_prefix ("/placeholder") URL prefix the middleware serves.
    # @option options [Integer] :image_max_dim_px (4000) maximum width or height, in pixels.
    # @option options [Integer] :image_max_total_px (16_000_000) maximum total pixel count.
    # @option options [String] :http_header_cache_control the +Cache-Control+ response header value.
    # @option options [Integer] :cache_max_entries (128) in-memory FIFO cache size; +0+ disables caching.
    # @option options [Array(Integer, Integer, Integer), String] :image_default_bg default background color.
    # @option options [Array(Integer, Integer, Integer), String] :image_default_fg default foreground color.
    # @raise [ArgumentError] if an option key is not present in {DEFAULTS} or a default color is invalid.
    def initialize(app, **options)
      unknown = options.keys - DEFAULTS.keys
      raise ArgumentError, "unknown option(s): #{unknown.join(', ')}" unless unknown.empty?

      @app     = app
      @options = DEFAULTS.merge(options)
      %i[image_default_bg image_default_fg].each { |key| @options[key] = resolve_default_color(key) }
      @cache   = {}
      @mutex   = Mutex.new

      path_prefix = Regexp.escape(@options[:path_prefix].chomp("/"))
      @owned = %r{\A#{path_prefix}/}
      @route = %r{\A#{path_prefix}/(#{DIMENSION})(?:x(#{DIMENSION}))?\.png\z}
    end

    # Rack entry point. Serves a PNG for owned paths and delegates everything else downstream.
    #
    # @param env [Hash] the Rack environment.
    # @return [Array(Integer, Hash, Array)] a Rack response tuple.
    def call(env)
      return @app.call(env) unless @owned.match?(env["PATH_INFO"])
      unless %w[GET HEAD].include?(env["REQUEST_METHOD"])
        return error(env["REQUEST_METHOD"], 405, "method not allowed", { "allow" => "GET, HEAD" })
      end

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

    def error(req_method, status, message, headers = {})
      body = req_method == "HEAD" ? "" : "#{message}\n"

      [
        status,
        headers.merge(
          "content-type" => "text/plain; charset=utf-8",
          "content-length" => body.bytesize.to_s
        ),
        [body]
      ]
    end

    # Fetch the image from the cache if available; otherwise generate (and cache).
    #
    # NOTE: Cached entries are compressed PNGs, so worst-case cache memory is
    #       ~ cache_max_entries * compressed_size_of_largest_allowed_image.
    #       Under the default config (entries=128 max_px=4000x4000) the largest
    #       image encodes to ~260 KB; yielding max ~35 MB per cache instance.
    def fetch(spec)
      @mutex.synchronize { return @cache[spec] if @cache.key?(spec) }

      # render outside the mutex: concurrent misses may trigger duplicate rendering
      # but that's better (cheap, idempotent) than serializing all rendering
      img = Renderer.call(**spec)

      if @options[:cache_max_entries].positive?
        @mutex.synchronize do
          @cache[spec] = img
          @cache.shift while @cache.size > @options[:cache_max_entries] # FIFO eviction
        end
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
      return default if value.nil? || value.empty?

      parse_hex_color(value) or raise BadRequest, "invalid color: #{truncate(value)}"
    end

    # @return [Array(Integer, Integer, Integer), nil] RGB bytes, or +nil+ if malformed.
    def parse_hex_color(value)
      hex = value.delete_prefix("#")
      hex = hex.chars.map { |c| c * 2 }.join if hex.length == 3
      return nil unless hex.match?(/\A\h{6}\z/)

      [hex[0, 2], hex[2, 2], hex[4, 2]].map { |pair| pair.to_i(16) }
    end

    def truncate(value)
      value.length > ERROR_VALUE_MAX_LENGTH ? "#{value[0, ERROR_VALUE_MAX_LENGTH]}..." : value
    end

    # Validates and resolves a configured default color to RGB bytes at boot.
    def resolve_default_color(key)
      value = @options[key]
      if value.is_a?(Array)
        return value if value.length == 3 && value.all? { |c| c.is_a?(Integer) && c.between?(0, 255) }
      elsif value.is_a?(String)
        rgb = parse_hex_color(value)
        return rgb if rgb
      end

      raise ArgumentError, "invalid #{key}: expected hex color string or array of RGB integers, got #{value.inspect}"
    end
  end
end
