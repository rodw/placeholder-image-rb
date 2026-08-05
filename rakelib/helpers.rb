# frozen_string_literal: true

require "net/http"
require "socket"

# Shared helpers for the smoke-test rake tasks (test:examples, test:docker):
# free-port allocation, HTTP probes against a booting server, and log-echoing
# failure reporting. (Not auto-loaded by rake, which globs rakelib/*.rake only;
# task files pull this in with require_relative.)

PNG_SIGNATURE = "\x89PNG\r\n\x1A\n".b

def free_port
  TCPServer.open("127.0.0.1", 0) { |server| server.addr[1] }
end

def wait_for_server(port, log, timeout: 30)
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
  fail_with_log("#{name}: GET #{path} returned HTTP #{response.code}", log) unless
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
