# frozen_string_literal: true

require "sinatra/base"
require "placeholder_image"

class ExampleApp < Sinatra::Base
  # mount the placeholder-image middleware
  # (overriding some of the default configuration)
  use PlaceholderImage::Middleware,
      path_prefix: "/image/placeholder",
      image_max_dim_px: 2_000,
      image_max_total_px: 4_000_000,
      cache_max_entries: 128,
      http_header_cache_control: "public, max-age=86400",
      image_default_bg: [0xEE, 0xEE, 0xEE],
      image_default_fg: [0x99, 0x99, 0x99]

  # add an application-specific route handler
  get "/" do
    content_type "text/html"

    <<~HTML
      <!doctype html>
      <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>Placeholder-Image in Sinatra</title>
        </head>
        <body>
          <h1>Using Placeholder-Image with Sinatra</h1>

          <p>This is a simple demonstration of using the placeholder-image middleware within a <a href="https://sinatrarb.com/">Sinatra</a> app.</p>
          <p>Note that the placeholder-image middleware has been mounted at <code>/image/placeholder/</code> (rather than the default <code>/placeholder</code>).</p>

          <hr>

          <p>Here is 120 x 120 pixel image, using the default colors:</p>
          <img
            src="/image/placeholder/120.png"
            width="120"
            height="120"
            alt="Generated 120x120 placeholder image"
          >
          <p><a href="/image/placeholder/120.png" target="_blank">Click here</a> to open the image directly in a new window.</p>

          <hr>

          <p>Here is 300 x 180 pixel image, using custom colors:</p>
          <img
            src="/image/placeholder/300x180.png?bg=111&fg=f90"
            width="300"
            height="180"
            alt="Generated 300x180 placeholder image"
          >
          <p><a href="/image/placeholder/300x180.png?bg=111&fg=f90" target="_blank">Click here</a> to open the image directly in a new window.</p>

        </body>
      </html>
    HTML
  end
end
