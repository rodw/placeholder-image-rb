# Contributing

Contributions to Placeholder-Image are welcome.

## Development Setup

Placeholder-Image requires Ruby 3.2 or newer.

Clone the repository:

```sh
git clone https://github.com/rodw/placeholder-image-rb.git
cd placeholder-image-rb
```

Install its dependencies:

```sh
bundle install
```

Run the test suite, lint, and type check:

```sh
bundle exec rake
```

For a more comprehensive test suite (one that also validates the [Docker image](./docker/) and each of the [example apps](./examples/)), use:

```sh
bundle exec rake test:all
```

To launch a local Rack server:

```sh
bundle exec rackup
```

Then you can visit <http://localhost:9292/placeholder/300.png> to see the service in action.


Demonstrations of integrating placeholder-image with Sinatra, Rails, and generic Rack apps are available in the [examples/](./examples/) directory.

Instructions for building and running the placeholder-image as stand-alone service can be found in the [docker/](./docker/README.md) directory.

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

## Git Branching Model

This repository follows a simplified form of the [git-flow](https://nvie.com/posts/a-successful-git-branching-model/#the-main-branches) branching model.

There are two primary, persistent branches:

  * The [`develop` branch](https://github.com/rodw/placeholder-image-rb/tree/develop) is the main integration point, where changes slated for future releases are typically staged. It contains the "latest and greatest" (pre-release) version of the code. It may contain changes that have not been released yet, but it should _always_ be release ready.

  * The [`main` branch](https://github.com/rodw/placeholder-image-rb/tree/main) contains the production version of the codebase. It's essentially a series of tagged checkpoints, each representing a released version of the system.

Note that `develop` is the "default" branch for this repo; the one you will land on by default when you do a `git clone`. This is by design. `develop` is the baseline from which any [contributions](#submitting-changes) should be built and to which they will eventually be merged back into.

## Submitting Changes

To contribute changes to this repo, create a pull request that targets the [`develop` branch](https://github.com/rodw/placeholder-image-rb/tree/develop).

Before submitting the pull request:

- Add or update tests for any functional changes,
- Run `bundle exec rake test:all` and ensure it completes successfully.
- Update the relevant documentation when any public behavior or configuration changes.
- Make sure to resolve any merge conflicts between your changes and the `develop` branch.
- Keep changes focused and explain their motivation in the pull request description.

## Releasing

Releases are published automatically by [the CI/CD workflows](https://github.com/rodw/placeholder-image-rb/tree/main/.github/workflows) when a release tag (`vN.N.N`) is pushed to [the main branch](https://github.com/rodw/placeholder-image-rb/tree/main).

The gem is published to the [RubyGems](https://rubygems.org/) repository as [placeholder-image](https://rubygems.org/gems/placeholder-image) by the [release workflow](https://github.com/rodw/placeholder-image-rb/blob/main/.github/workflows/release.yml) using [Trusted Publishing](https://guides.rubygems.org/trusted-publishing/) (OIDC), so no API key is stored in the repository.

The Docker image is published to the [GitHub Container Registry](https://ghcr.io) as [ghcr.io/rodw/placeholder-image](https://ghcr.io/rodw/placeholder-image) (tagged `X.Y.Z`, `X.Y`, and `latest`) by the [docker-publish workflow](https://github.com/rodw/placeholder-image-rb/blob/main/.github/workflows/docker-publish.yml). It authenticates with the workflow's `GITHUB_TOKEN`; no secret setup is required.

**To cut a release**

1. Create a release branch off of [develop](https://github.com/rodw/placeholder-image-rb/tree/develop) using the [git-flow](https://github.com/nvie/gitflow#creating-featurereleasehotfixsupport-branches) workflow:

   ```sh
   # First grab the latest version of develop...
   git checkout develop
   git pull
   # ...and verify that it builds cleanly.
   bundle exec rake test:all
   ```

   ```sh
   # Then create the release branch
   git flow release start 1.2.3
   # where here we assume the next release will be v1.2.3.
   ```

2. Make some final changes:
   1. Bump the version number in [lib/placeholder_image/version.rb](./lib/placeholder_image/version.rb).

   2. Update [CHANGELOG.md](./CHANGELOG.md) with release notes describing what has changed since the last release.

      - By convention unreleased changes will often already be described under the heading `## Unreleased`, so you _may_ only need to change that label to `## v1.2.3 - YYYY-MM-DD`.

      - To see a list of all commits made since the last release, you can use:
         ```sh
         # fetching the name of the most recent tag on main automatically:
         git log $(git describe main --tags --abbrev=0)..HEAD --oneline
         # or, to specify the previous release tag directly:
         git log v1.2.2..HEAD --oneline
         ```

   3. Run `bundle exec rake docker:lock` to refresh [docker/Gemfile.lock](./docker/Gemfile.lock). This updates and records the latest version of each of the gem's dependencies. The Docker image build is pinned to those versions, for reproducibility.
   <br>

3. Commit those changes and run `bundle exec rake test:all` one final time to make sure everything is still working as expected.
   <br>

4. Close out the release branch using the git-flow workflow: `git flow release finish 1.2.3`. This will merge the changes back into  `develop`, forward into `main`, and tag the release (as `v1.2.3`).
   <br>

1. Push the changes upstream:

   ```sh
   # push the branches (--atomic ensures they both succeed or both fail)
   git push --atomic origin develop main

   # push the tag
   git push origin v1.2.3
   ```

2. The tag push will trigger both of the CI/CD workflows [described above](#releasing), running the full build and publishing both the [Ruby gem](https://rubygems.org/gems/placeholder-image) and [Docker image](https://ghcr.io/rodw/placeholder-image). You can visit the [GitHub Actions](https://github.com/rodw/placeholder-image-rb/actions) page for this repo to track the status of those builds.
