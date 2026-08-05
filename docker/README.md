# Stand-alone Docker Server

Placeholder-Image can be run as a stand-alone, containerized service. 

## Launching

Run these commands from the project root to build and launch a production-mode
Puma server:

```sh
docker build --file docker/Dockerfile --tag placeholder-image .
docker run --rm --publish 9292:9292 placeholder-image
```

Then open <http://localhost:9292/placeholder/300.png>.

## Configuration

The container runs as a non-root user and exposes port `9292`. The bind address,
port, and maximum Puma thread count can be overridden with the `HOST`, `PORT`,
and `MAX_THREADS` environment variables:

| Environment variable | Default | Description |
| --- | --- | --- |
| `HOST` | `0.0.0.0` | Address on which Puma listens. |
| `PORT` | `9292` | Container port on which Puma listens. |
| `MAX_THREADS` | `5` | Maximum number of threads used by Puma. |

Every middleware option can also be set with an environment variable:

| Environment variable | Middleware option | Default | Description |
| --- | --- | --- | --- |
| `PATH_PREFIX` | `path_prefix` | `/placeholder` | URL path prefix under which generated images are served |
| `HTTP_HEADER_CACHE_CONTROL` | `http_header_cache_control` | `public, max-age=31536000, immutable` | Value of the `Cache-Control` HTTP response header |
| `IMAGE_MAX_DIM_PX` | `image_max_dim_px` | `4000` | Maximum permitted width or height, in pixels |
| `IMAGE_MAX_TOTAL_PX` | `image_max_total_px` | `16000000` | Maximum permitted total pixel count (`width * height`) |
| `IMAGE_DEFAULT_BG` | `image_default_bg` | `#eeeeee` | Default background color |
| `IMAGE_DEFAULT_FG` | `image_default_fg` | `#999999` | Default foreground color |
| `CACHE_MAX_ENTRIES` | `cache_max_entries` | `128`  | Maximum number of generated images retained in each middleware instance's in-memory FIFO cache. Set to `0` to disable caching. |

For example:

```sh
docker run --rm --publish 9292:9292 \
  --env PATH_PREFIX=/images \
  --env IMAGE_MAX_DIM_PX=2000 \
  --env IMAGE_MAX_TOTAL_PX=4000000 \
  --env 'HTTP_HEADER_CACHE_CONTROL=no-store' \
  --env CACHE_MAX_ENTRIES=64 \
  --env 'IMAGE_DEFAULT_BG=#fff' \
  --env 'IMAGE_DEFAULT_FG=#333' \
  placeholder-image
```

[See the middleware documentation](../README.md#configuration)  for more detail on these configuration options.

### Port Mapping

`EXPOSE 9292` documents the default container port and does not change when
`PORT` is overridden. Either map a different host port to the default container
port:

```sh
docker run --rm --publish 8080:9292 placeholder-image
```

or set `PORT` and publish the matching container port:

```sh
docker run --rm --publish 8080:8080 --env PORT=8080 placeholder-image
```
