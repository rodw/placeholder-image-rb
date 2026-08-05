# frozen_string_literal: true

require "placeholder_image"
require "rack/static"

# Mount the placeholder-image middleware, overriding some defaults.
use PlaceholderImage::Middleware,
    path_prefix: "/img",
    image_max_dim_px: 2_000,
    image_max_total_px: 4_000_000,
    cache_max_entries: 128,
    http_header_cache_control: "public, max-age=86400",
    image_default_bg: [0xEE, 0xEE, 0xEE],
    image_default_fg: [0x99, 0x99, 0x99]

# Serve the stand-alone demonstration page at the application root.
use Rack::Static,
    urls: { "/" => "index.html" },
    root: File.expand_path("public", __dir__)

run lambda { |_env|
  body = "not found\n"
  [404,
   { "content-type" => "text/plain; charset=utf-8",
     "content-length" => body.bytesize.to_s },
   [body]]
}
