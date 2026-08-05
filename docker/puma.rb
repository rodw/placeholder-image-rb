# frozen_string_literal: true

host = ENV.fetch("HOST", "0.0.0.0")
port = Integer(ENV.fetch("PORT", "9292"))
max_threads = Integer(ENV.fetch("MAX_THREADS", "5"))

bind "tcp://#{host}:#{port}"
threads 0, max_threads
environment ENV.fetch("RACK_ENV", "production")
rackup File.expand_path("config.ru", __dir__)
