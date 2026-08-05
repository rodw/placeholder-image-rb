# frozen_string_literal: true

require_relative "boot"

require "rails"
require "action_controller/railtie"

Bundler.require(*Rails.groups)

module PlaceholderImageRailsExample
  class Application < Rails::Application
    config.load_defaults 8.1

    # Mount the placeholder-image middleware, overriding some defaults.
    config.middleware.use PlaceholderImage::Middleware,
                          path_prefix: "/img/ph",
                          image_max_dim_px: 2_000,
                          image_max_total_px: 4_000_000,
                          cache_max_entries: 128,
                          http_header_cache_control: "public, max-age=86400",
                          image_default_bg: [0xEE, 0xEE, 0xEE],
                          image_default_fg: [0x99, 0x99, 0x99]
  end
end
