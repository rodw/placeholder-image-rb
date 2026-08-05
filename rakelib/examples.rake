# frozen_string_literal: true

require "net/http"
require "socket"

# Smoke tests for the example applications in examples/: each example is
# bundled, booted with Puma on a free port, and probed for its demo page and a
# generated placeholder image. Subprocess output (bundler, puma) is captured in
# tmp/smoke-<name>.log and echoed back only when something fails.

EXAMPLE_IMAGE_PATHS = {
  "rack" => "/img/40.png",
  "sinatra" => "/image/placeholder/40.png",
  "rails" => "/img/ph/40.png"
}.freeze

EXAMPLE_PNG_SIGNATURE = "\x89PNG\r\n\x1A\n".b

namespace :test do
  namespace :examples do
    EXAMPLE_IMAGE_PATHS.each do |name, image_path|
      desc "Smoke-test the #{name} example (bundle install, boot, fetch the demo page and an image)"
      task name do
        smoke_test_example(name, image_path)
      end
    end
  end

  desc "Smoke-test every example application"
  task examples: EXAMPLE_IMAGE_PATHS.keys.map { |name| "examples:#{name}" }
end

def smoke_test_example(name, image_path)
  log = File.expand_path("../tmp/smoke-#{name}.log", __dir__)
  FileUtils.mkdir_p(File.dirname(log))
  File.write(log, "")

  Bundler.with_unbundled_env do
    Dir.chdir(File.expand_path("../examples/#{name}", __dir__)) do
      puts "#{name} example: installing and booting (log: #{log})"
      unless system("bundle install --quiet", %i[out err] => [log, "a"])
        fail_with_log("#{name} example: bundle install failed", log)
      end

      with_example_server(log) do |port|
        fetch_ok(name, port, "/", log)
        image = fetch_ok(name, port, image_path, log)
        fail_with_log("#{name} example: GET #{image_path} did not return a PNG", log) unless
          image.start_with?(EXAMPLE_PNG_SIGNATURE)
      end
    end
  end

  puts "#{name} example: smoke test passed"
end

def with_example_server(log)
  port = free_port
  pid = Process.spawn("bundle", "exec", "puma", "--port", port.to_s, %i[out err] => [log, "a"])
  begin
    wait_for_example_server(port, log)
    yield port
  ensure
    begin
      Process.kill("TERM", pid)
      Process.wait(pid)
    rescue Errno::ESRCH, Errno::ECHILD
      nil # the server already exited
    end
  end
end

def free_port
  TCPServer.open("127.0.0.1", 0) { |server| server.addr[1] }
end

def wait_for_example_server(port, log, timeout: 30)
  deadline = Time.now + timeout
  begin
    Net::HTTP.get_response(URI("http://127.0.0.1:#{port}/"))
  rescue SystemCallError
    fail_with_log("server did not start within #{timeout}s", log) if Time.now > deadline

    sleep 0.2
    retry
  end
end

def fetch_ok(name, port, path, log)
  response = Net::HTTP.get_response(URI("http://127.0.0.1:#{port}#{path}"))
  fail_with_log("#{name} example: GET #{path} returned HTTP #{response.code}", log) unless
    response.is_a?(Net::HTTPOK)

  response.body
end

# Echo the captured subprocess log (so failures are debuggable in CI, where the
# log file itself is not retrievable), then fail the task.
def fail_with_log(message, log)
  tail = File.exist?(log) ? File.readlines(log).last(50) : []
  unless tail.empty?
    warn "----- #{log} (last #{tail.length} lines) -----"
    tail.each { |line| warn line.chomp }
    warn "-----"
  end

  raise message
end
