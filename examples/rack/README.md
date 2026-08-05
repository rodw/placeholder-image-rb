# Rack Example

This directory contains a framework-free [Rack](https://rack.github.io/) application that integrates the [placeholder-image](https://github.com/rodw/placeholder-image-rb/) middleware.

## Quick Start

To install the dependencies and launch the application, run:

```sh
bundle install
bundle exec rackup
```

You may then visit the following URLs:

- Application: <http://localhost:9292/>
- Square image: <http://localhost:9292/img/300.png>
- Rectangular image: <http://localhost:9292/img/640x360.png>
- Custom colors: <http://localhost:9292/img/640x360.png?bg=1d3557&fg=f1faee>

The middleware is mounted at `/img/`, rather than its default
`/placeholder` prefix. See [config.ru](config.ru) for the Rack stack.

## Files

- [Gemfile](Gemfile) imports Puma, Rackup, and the local placeholder-image gem.
- [config.ru](config.ru) builds the middleware stack and serves the application with Rackup.
- [public/index.html](public/index.html) is the static demonstration page served by `Rack::Static`.
