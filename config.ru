# frozen_string_literal: true

require "placeholder_image"

use PlaceholderImage::Middleware

run lambda { |_env|
  body = "Try /placeholder/300.png\n"
  [404, { "content-type" => "text/plain", "content-length" => body.bytesize.to_s }, [body]]
}
