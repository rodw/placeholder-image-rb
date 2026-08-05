# syntax=docker/dockerfile:1

# -- STAGE 1: BASELINE RUBY IMAGE ---------------------------------------------
FROM ruby:4.0.6-slim-trixie AS base
WORKDIR /app

# -- STAGE 2: BUILD GEMFILE FROM SOURCE ---------------------------------------
FROM base AS build

# BUNDLE_FROZEN makes bundle install fail if docker/Gemfile and its committed
# lockfile have drifted (regenerate with `bundle exec rake docker:lock`).
ENV BUNDLE_GEMFILE=/app/docker/Gemfile \
    BUNDLE_FROZEN=true

RUN apt-get update && \
    apt-get install --no-install-recommends --yes build-essential && \
    rm -rf /var/lib/apt/lists/*

COPY docker/Gemfile docker/Gemfile.lock ./docker/
COPY placeholder-image.gemspec ./
COPY CHANGELOG.md LICENSE.txt README.md ./
COPY lib ./lib

RUN gem build placeholder-image.gemspec --output /tmp/placeholder-image.gem && \
    bundle config set path.system true && \
    bundle install && \
    gem install /tmp/placeholder-image.gem \
        --local \
        --ignore-dependencies \
        --no-document

# -- STAGE 3: COPY FROM BUILD INTO RUNTIME IMAGE ------------------------------
FROM base AS runtime

ENV RACK_ENV=production \
    HOST=0.0.0.0 \
    PORT=9292 \
    MAX_THREADS=5 \
    PATH_PREFIX=/placeholder \
    IMAGE_MAX_DIM_PX=4000 \
    IMAGE_MAX_TOTAL_PX=16000000 \
    HTTP_HEADER_CACHE_CONTROL="public, max-age=31536000, immutable" \
    CACHE_MAX_ENTRIES=128 \
    IMAGE_DEFAULT_BG="#eeeeee" \
    IMAGE_DEFAULT_FG="#999999"

RUN groupadd --gid 1000 app && \
    useradd --uid 1000 --gid app --create-home --shell /usr/sbin/nologin app

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --chown=app:app docker/config.ru ./docker/config.ru
COPY --chown=app:app docker/puma.rb ./docker/puma.rb

USER app

EXPOSE 9292

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ruby -rsocket -e 'socket = TCPSocket.new("127.0.0.1", ENV.fetch("PORT", "9292")); path = ENV.fetch("PATH_PREFIX", "/placeholder").chomp("/"); socket.write("GET #{path}/1.png HTTP/1.0\r\n\r\n"); abort unless socket.gets&.include?("200")'

CMD ["puma", "--config", "docker/puma.rb"]
