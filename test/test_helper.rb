# frozen_string_literal: true

if ENV["COVERAGE"] == "true"
  require "simplecov"

  SimpleCov.start do
    cover "lib/**/*.rb"
    skip "lib/placeholder_image/version.rb"
    enable_coverage :line, :branch, :method
    minimum_coverage line: 90, branch: 85, method: 90
  end
end

require "minitest/autorun"
require "rack/mock"
require "placeholder_image"
