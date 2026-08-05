# Contributing

Contributions to Placeholder Image are welcome.

## Development Setup

Placeholder Image requires Ruby 3.2 or newer.

Clone the repository and install its dependencies:

```sh
bundle install
```

Run the test suite and lint checks:

```sh
bundle exec rake
```

To launch the local Rack server:

```sh
bundle exec rackup
```

Then open <http://localhost:9292/placeholder/300.png>.

Additional integration examples are available in the [examples](examples/)
directory. Instructions for building and running the stand-alone container are
in the [Docker documentation](docker/README.md).

## Development Tasks

```sh
bundle exec rake                     # test, lint, typecheck
bundle exec rake build               # build the gem (into ./pkg)

bundle exec rake yard                # build API documentation (into ./doc)
bundle exec rake docker:lock         # regenerate docker/Gemfile.lock (after Gemfile or version changes)

bundle exec rake test                # run the unit test suite

bundle exec rake test:coverage       # generate a coverage report (into ./coverage)
bundle exec simplecov open           # open the coverage report

bundle exec rake rubocop             # run RuboCop (lint/style check)
bundle exec rake rubocop:autocorrect # apply safe autocorrections

bundle exec rake typecheck           # validate RBS and run Steep

bundle exec rake test:docker         # smoke-test the Docker image (build, run, fetch an image)

bundle exec rake test:examples       # smoke-test every example app (bundle, boot, fetch an image)
bundle exec rake test:examples:rack  # smoke-test a single example (also: sinatra, rails)

bundle exec rake test:all            # test, lint, typecheck, smoke-test docker, smoke-text example apps

bundle exec rake clean               # remove temporary files
bundle exec rake clobber             # remove all generated files

bundle exec rake -T                  # list all rake targets
```

## Submitting Changes

Before submitting a pull request:

- Add or update tests for behavior changes.
- Update documentation when public behavior or configuration changes.
- Run `bundle exec rake` and ensure it completes successfully.
- Keep changes focused and explain their motivation in the pull request.

## Releasing

Releases are published automatically when a release tag is pushed:

- The gem is published to [RubyGems](https://rubygems.org/gems/placeholder-image)
  by the [`Release` workflow](.github/workflows/release.yml) using
  [Trusted Publishing](https://guides.rubygems.org/trusted-publishing/) (OIDC),
  so no API key is stored in the repository.
- The container image is published to
  [GitHub Container Registry](https://ghcr.io) as
  `ghcr.io/rodw/placeholder-image` by the
  [`Docker Publish` workflow](.github/workflows/docker-publish.yml), tagged
  `X.Y.Z`, `X.Y`, and `latest`. It authenticates with the workflow's
  `GITHUB_TOKEN`; no secret setup is required.

To cut a release:

1. Bump `PlaceholderImage::VERSION` and update `CHANGELOG.md`.
2. Run `bundle exec rake docker:lock` to refresh `docker/Gemfile.lock` (it
   records the gem's version; container builds are frozen against it).
3. Push the changes to `main`.
4. Tag the release and push the tag:

   ```sh
   git tag v1.2.0
   git push origin v1.2.0
   ```

The tag push triggers both workflows, which run the full build and publish the
gem and the image.

One-time setup:

- RubyGems: configure a Trusted Publisher for `placeholder-image` pointing at
  `rodw/placeholder-image-rb` and the `Release` workflow.
- GHCR: nothing is required before the first publish (the package is created
  automatically and linked to this repository). After the first publish, make
  the package public: on github.com, go to your profile → *Packages* →
  `placeholder-image` → *Package settings* → *Change visibility* → Public.
  Until then, `docker pull` requires authentication.
