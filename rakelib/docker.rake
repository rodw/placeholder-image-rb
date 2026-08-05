# frozen_string_literal: true

require_relative "helpers"

# Docker-related tasks: a smoke test that builds and probes the stand-alone
# container (see docker/), and a helper that regenerates docker/Gemfile.lock.
# Smoke-test subprocess output (docker build/run/logs) is captured in
# tmp/smoke-docker.log and echoed back only when something fails.

DOCKER_SMOKE_IMAGE = "placeholder-image:smoke"
DOCKER_SMOKE_CONTAINER = "placeholder-image-smoke"

# Platforms recorded in docker/Gemfile.lock. The lockfile may be generated on
# any host (e.g. macOS/arm64) but is consumed inside the Linux container, where
# a missing platform would make the frozen bundle install fail.
DOCKER_LOCK_PLATFORMS = %w[x86_64-linux aarch64-linux ruby].freeze

namespace :test do
  desc "Smoke-test the Docker image (docker build, run, fetch a generated image)"
  task :docker do
    smoke_test_docker
  end
end

namespace :docker do
  desc "Regenerate docker/Gemfile.lock (run after changing docker/Gemfile or bumping the gem version)"
  task :lock do
    Bundler.with_unbundled_env do
      Dir.chdir(File.expand_path("..", __dir__)) do
        sh({ "BUNDLE_GEMFILE" => "docker/Gemfile" },
           "bundle", "lock", "--update", "--add-platform", *DOCKER_LOCK_PLATFORMS)
      end
    end
  end
end

def smoke_test_docker
  log = File.expand_path("../tmp/smoke-docker.log", __dir__)
  FileUtils.mkdir_p(File.dirname(log))
  File.write(log, "")

  Dir.chdir(File.expand_path("..", __dir__)) do
    unless system("docker info", %i[out err] => [log, "a"])
      raise "docker: the Docker daemon is not available; start Docker to run this task"
    end

    puts "docker: building #{DOCKER_SMOKE_IMAGE} (log: #{log})"
    unless system("docker build --file docker/Dockerfile --tag #{DOCKER_SMOKE_IMAGE} .", %i[out err] => [log, "a"])
      fail_with_log("docker: image build failed", log)
    end

    with_docker_container(log) { |port| probe_docker_container(port, log) }
  end

  puts "docker: smoke test passed"
end

def probe_docker_container(port, log)
  image = fetch_ok("docker", port, "/placeholder/1.png", log)
  fail_with_log("docker: /placeholder/1.png did not return a PNG", log) unless
    image.start_with?(PNG_SIGNATURE)

  root = Net::HTTP.get_response(URI("http://127.0.0.1:#{port}/"))
  fail_with_log("docker: expected HTTP 404 from the fallback app at /, got #{root.code}", log) unless
    root.is_a?(Net::HTTPNotFound)
end

def with_docker_container(log)
  port = free_port
  # Remove any leftover container from a previous aborted run.
  system("docker rm --force #{DOCKER_SMOKE_CONTAINER}", %i[out err] => File::NULL)

  run = ["docker run --detach --rm --publish #{port}:9292", "--name #{DOCKER_SMOKE_CONTAINER}",
         DOCKER_SMOKE_IMAGE].join(" ")
  fail_with_log("docker: failed to start the container", log) unless system(run, %i[out err] => [log, "a"])

  begin
    wait_for_server(port, log)
    yield port
  ensure
    system("docker logs #{DOCKER_SMOKE_CONTAINER}", %i[out err] => [log, "a"])
    system("docker rm --force #{DOCKER_SMOKE_CONTAINER}", %i[out err] => [log, "a"])
  end
end
