# frozen_string_literal: true

require_relative "lib/placeholder_image/version"

Gem::Specification.new do |spec|
  spec.name = "placeholder-image"
  spec.version = PlaceholderImage::VERSION
  spec.authors = ["Rodney Waldhoff"]
  spec.summary = "Rack middleware for generating placeholder images"
  spec.description = "A small, dependency-light Rack middleware that generates simple placeholder images."
  spec.homepage = "https://github.com/rodw/placeholder-image-rb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2", "< 5.0"

  spec.metadata = {
    "bug_tracker_uri" => "https://github.com/rodw/placeholder-image-rb/issues",
    "changelog_uri" => "https://github.com/rodw/placeholder-image-rb/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://rubydoc.info/gems/placeholder-image",
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir.glob(%w[lib/**/*.rb sig/**/*.rbs LICENSE.txt README.md CHANGELOG.md SECURITY.md])
  spec.require_paths = ["lib"]

  spec.add_dependency "rack", ">= 3.0", "< 4.0"
end
