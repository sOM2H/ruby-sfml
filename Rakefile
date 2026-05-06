require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rdoc/task"

require_relative "lib/sfml/version"

RSpec::Core::RakeTask.new(:spec)

RDoc::Task.new do |rdoc|
  rdoc.main         = "README.md"
  rdoc.title        = "ruby-sfml #{SFML::VERSION}"
  rdoc.rdoc_dir     = "doc"
  rdoc.markup       = "markdown"
  # Public API only. Skip the FFI plumbing under SFML::C — it's documented
  # by being mechanical, and RDoc'ing every attach_function would drown the
  # reader.
  rdoc.options << "--exclude=lib/sfml/c.rb"
  rdoc.options << "--exclude=lib/sfml/c/"
  rdoc.rdoc_files.include("README.md", "LICENSE.txt", "lib/**/*.rb")
end

task default: :spec
