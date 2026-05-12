require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rdoc/task"

require_relative "lib/sfml/version"

RSpec::Core::RakeTask.new(:spec)

RDoc::Task.new do |rdoc|
  # Most project-wide knobs (markup, excludes, template, …) live in
  # `.rdoc_options`, which is ALSO read by the bare `rdoc` CLI that
  # the docs-site repo invokes. Keep this task minimal — title +
  # version interpolation can't live in the YAML, the rest can.
  rdoc.title    = "ruby-sfml #{SFML::VERSION}"
  rdoc.rdoc_dir = "doc"
  rdoc.rdoc_files.include("README.md", "CHANGELOG.md", "LICENSE.txt", "lib/**/*.rb")
end

task default: :spec
