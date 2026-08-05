# Changelog

All notable changes to this project will be documented here. This project follows
[Semantic Versioning](https://semver.org/).

## Unreleased

  - Validate configuration at boot: unknown option keys and invalid default colors now raise `ArgumentError` when the middleware is constructed. 
  - Narrow path ownership to `<path_prefix>/`: the bare prefix (`/placeholder`) and sibling paths such as `/placeholder.css` are now passed through to the downstream application instead of returning `400 Bad Request`.
  - Include the `Allow` header in `405 Method Not Allowed` responses.
  - Truncate client-supplied color values echoed in `400 Bad Request` messages.

## v1.0.0 - 2026-08-05

  - Initial release. Includes PNG-generating Rack middleware, stand-alone Docker service, and complete examples of integrating with Sinatra, Rails, and generic Rack applications.

