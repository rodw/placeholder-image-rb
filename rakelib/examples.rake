# frozen_string_literal: true

require_relative "helpers"

# Smoke tests for the example applications in examples/: each example is
# bundled, booted with Puma on a free port, and probed for its demo page and a
# generated placeholder image. Subprocess output (bundler, puma) is captured in
# tmp/smoke-<name>.log and echoed back only when something fails.

EXAMPLE_IMAGE_PATHS = {
  "rack" => "/img/40.png",
  "sinatra" => "/image/placeholder/40.png",
  "rails" => "/img/ph/40.png"
}.freeze

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
  label = "#{name} example"
  log = File.expand_path("../tmp/smoke-#{name}.log", __dir__)
  FileUtils.mkdir_p(File.dirname(log))
  File.write(log, "")

  Bundler.with_unbundled_env do
    Dir.chdir(File.expand_path("../examples/#{name}", __dir__)) do
      puts "#{label}: installing and booting (log: #{log})"
      unless system("bundle install --quiet", %i[out err] => [log, "a"])
        fail_with_log("#{label}: bundle install failed", log)
      end

      with_example_server(log) do |port|
        fetch_ok(label, port, "/", log)
        image = fetch_ok(label, port, image_path, log)
        fail_with_log("#{label}: GET #{image_path} did not return a PNG", log) unless
          image.start_with?(PNG_SIGNATURE)
      end
    end
  end

  puts "#{label}: smoke test passed"
end

def with_example_server(log)
  port = free_port
  pid = Process.spawn("bundle", "exec", "puma", "--port", port.to_s, %i[out err] => [log, "a"])
  begin
    wait_for_server(port, log)
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
