# frozen_string_literal: true

require "bundler/gem_tasks"
require "minitest/test_task"
require "rake/clean"
require "rubocop/rake_task"
require "steep/rake_task"
require "yard"

CLEAN.include("**/tmp", "**/log/*.log")
CLOBBER.include("coverage", "doc", ".yardoc", "examples/**/Gemfile.lock")

Minitest::TestTask.create
RuboCop::RakeTask.new
Steep::RakeTask.new
YARD::Rake::YardocTask.new

task default: %i[test rubocop steep]

desc "Validate RBS signatures and run the Steep type checker"
task typecheck: %i[steep]

desc "Run the test suite and generate a coverage report"
task "test:coverage" do
  ENV["COVERAGE"] = "true"
  Rake::Task["test"].invoke
end
