# frozen_string_literal: true

require "placeholder_image"

path_prefix = ENV.fetch("PATH_PREFIX", "/placeholder")

use PlaceholderImage::Middleware,
    path_prefix: path_prefix,
    image_max_dim_px: Integer(ENV.fetch("IMAGE_MAX_DIM_PX", "4000")),
    image_max_total_px: Integer(ENV.fetch("IMAGE_MAX_TOTAL_PX", "16000000")),
    http_header_cache_control: ENV.fetch("HTTP_HEADER_CACHE_CONTROL", "public, max-age=31536000, immutable"),
    cache_max_entries: Integer(ENV.fetch("CACHE_MAX_ENTRIES", "128")),
    image_default_bg: ENV.fetch("IMAGE_DEFAULT_BG", "#eeeeee"),
    image_default_fg: ENV.fetch("IMAGE_DEFAULT_FG", "#999999")

run lambda { |_env|
  body = "Try #{path_prefix.chomp('/')}/300.png\n"
  [404, { "content-type" => "text/plain", "content-length" => body.bytesize.to_s }, [body]]
}
