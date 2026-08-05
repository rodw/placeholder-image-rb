# Sinatra Example

This directory contains a simple example of a [Sinatra](https://sinatrarb.com/) app that integrates the [placeholder-image](../../) middleware.

## Quick Start

To install dependencies and launch the Sinatra app, run:

```sh
bundle install
bundle exec rackup
```

You may then visit the following URLs:

  * Application: http://localhost:9292/
  * Square image: http://localhost:9292/image/placeholder/300.png
  * Rectangular image: http://localhost:9292/image/placeholder/640x360.png
  * Custom colors: http://localhost:9292/image/placeholder/640x360.png?bg=1d3557&fg=f1faee

Note that the placeholder-image middleware has been mounted at `/image/placeholder/` (rather than the default `/placeholder`). See [app.rb](./app.rb) for details.

## Files

  * [Gemfile](./Gemfile) - the Gemfile for this example app; importing placeholder-image, sinatra, and other 3rd-party dependencies.

  * [config.ru](./config.ru) - Rack configuration file; launching the Sinatra app defined in [app.rb](./app.rb).

  * [app.rb](./app.rb) - the Sinatra app itself; mounting the placeholder-image middleware and declaring a custom route handler.