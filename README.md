# Placeholder Image

A dependency-light Rack middleware that generates simple placeholder images in pure Ruby (stdlib zlib only, no image gem dependencies). 

[![CI](https://github.com/rodw/placeholder-image-rb/actions/workflows/ci.yml/badge.svg)](https://github.com/rodw/placeholder-image-rb/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/placeholder-image.svg)](https://badge.fury.io/rb/placeholder-image)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.2-CC342D)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE.txt)

<p>
  <img
    src="https://raw.githubusercontent.com/rodw/placeholder-image-rb/main/examples/images/example-100x160.png"
    alt="A 100 by 160 pixel placeholder using the default colors"
    width="100"
    align="middle"
    title="/placeholder/100x160.png">
  <img
    src="https://raw.githubusercontent.com/rodw/placeholder-image-rb/main/examples/images/example-640x360-bg1D3557-fgF1FAEE.png"
    alt="A 640 by 360 pixel placeholder with custom colors"
    width="320"
    align="middle"
    title="/placeholder/640x360.png?bg=1d3557&fg=f1faee">
  <img
    src="https://raw.githubusercontent.com/rodw/placeholder-image-rb/main/examples/images/example-120-bg000-fgF90.png"
    alt="A 120-pixel square placeholder with custom colors"
    width="120"
    align="middle"
    title="/placeholder/120.png?bg=000&fg=f90">
</p>

## Installation

Placeholder-Image requires Ruby 3.2+ and Rack 3.

Add it to your bundle:

```ruby
gem "placeholder-image"
```

Then install:

```sh
bundle install
```

## Using

Placeholder-Image runs as standard Rack middleware:

```ruby
require "placeholder_image"

use PlaceholderImage::Middleware, path_prefix: "/placeholder"
run MyApp
```

The URL path specifies a square or rectangular image, with optional background and foreground colors as 3- or 6-digit hex codes:

```text
/placeholder/300.png
/placeholder/640x480.png
/placeholder/640x480.png?bg=eee&fg=1d3557
```

See [the examples](https://github.com/rodw/placeholder-image-rb/tree/main/examples) for complete demonstrations of integrating placeholder-image with Sinatra, Rails, and vanilla Rack applications.

## Configuration

Pass configuration options as keyword arguments when adding the middleware:

```ruby
use PlaceholderImage::Middleware,
    path_prefix: "/placeholder",
    http_header_cache_control: "public, max-age=31536000, immutable",
    image_max_dim_px: 4_000,
    image_max_total_px: 4_000 * 4_000,
    image_default_bg: "#eeeeee",
    image_default_fg: "#909",
    cache_max_entries: 128
```

| Option | Default | Description |
| --- | --- | --- |
| `path_prefix` | `/placeholder` | URL path prefix under which generated images are served. For example, the default serves `/placeholder/300.png`. A trailing slash is optional. |
| `http_header_cache_control` | `public, max-age=31536000, immutable` | Value of the `Cache-Control` response header. The default allows public caches to retain an image for one year. |
| `image_max_dim_px` | `4000` | Maximum permitted width or height, in pixels. Requests exceeding this limit return `400 Bad Request`. |
| `image_max_total_px` | `16000000` | Maximum permitted total pixel count (`width * height`). This limits the CPU time and memory consumed by a single image. Requests exceeding this limit return `400 Bad Request`. |
| `image_default_bg` | `[0xEE,0xEE,0xEE]` | Default background color as an RGB byte array or a 3- or 6-digit hex string, optionally beginning with `#`. The request's `bg` parameter overrides it. |
| `image_default_fg` | `[0x99,0x99,0x99]`| Default foreground color used for the border and dimension label. It accepts the same array and hex-string formats as `image_default_bg`; the request's `fg` parameter overrides it. |
| `cache_max_entries` | `128` | Maximum number of generated images retained in each middleware instance's in-memory FIFO cache. Set to `0` to disable caching. |

Note that cached entries are compressed PNGs, so worst-case cache memory is roughly `cache_max_entries` times the compressed size of the largest allowed image. Under the default configuration (128 entries, max size 4000x4000 pixels) the largest image encodes to roughly 260 KB yielding a max cache size around 35 MB.

## Running as a Stand-Alone Container

Placeholder-Image can be run as a stand-alone, containerized service. 

See the [Docker server documentation](https://github.com/rodw/placeholder-image-rb/blob/main/docker/README.md) for details.

## Development

For development setup and contribution guidelines, see
[CONTRIBUTING.md](https://github.com/rodw/placeholder-image-rb/blob/main/CONTRIBUTING.md).

## License

Placeholder-Image is available under the [MIT License](https://github.com/rodw/placeholder-image-rb/blob/main/LICENSE.txt).
