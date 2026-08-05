# Rails Example

This directory contains a small Rails 8 application that integrates the
[placeholder-image](../../) middleware. It intentionally omits Active Record,
JavaScript, and asset-pipeline dependencies so the middleware integration stays
easy to see.

## Quick Start

To install the dependencies and launch the Rails app, run:

```sh
bundle install
bundle exec rails server
```

You may then visit the following URLs:

- Application: <http://localhost:3000/>
- Square image: <http://localhost:3000/img/ph/300.png>
- Rectangular image: <http://localhost:3000/img/ph/640x360.png>
- Custom colors: <http://localhost:3000/img/ph/640x360.png?bg=1d3557&fg=f1faee>

The middleware is mounted at `/img/ph/`, rather than its default
`/placeholder` prefix. See [config/application.rb](config/application.rb) for
the integration.

To confirm its position in Rails' Rack stack, run:

```sh
bundle exec rails middleware
```

## Files

- [Gemfile](Gemfile) imports Rails, Puma, and the local placeholder-image gem.
- [config/application.rb](config/application.rb) configures the middleware.
- [config/routes.rb](config/routes.rb) declares the example application's root route.
- [app/controllers/home_controller.rb](app/controllers/home_controller.rb) renders the demonstration page.
- [app/views/home/index.html.erb](app/views/home/index.html.erb) embeds generated placeholder images.
