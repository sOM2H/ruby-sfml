require_relative "lib/sfml/version"

Gem::Specification.new do |spec|
  spec.name        = "ruby-sfml"
  spec.version     = SFML::VERSION
  spec.authors     = ["Mykhailo Melnyk"]
  spec.email       = ["m1kh41l.melnyk@gmail.com"]

  spec.summary     = "Modern Ruby bindings for SFML 3.x"
  spec.description = "Idiomatic Ruby bindings for SFML 3 via CSFML and FFI. Build games and multimedia apps in Ruby."
  spec.homepage    = "https://github.com/sOM2H/ruby-sfml"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"]    = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"

  spec.files = Dir[
    "lib/**/*.rb",
    "lib/sfml/assets/**/*",
    "ext/**/*.rb",
    "README.md",
    "LICENSE.txt",
    "ruby-sfml.gemspec"
  ]
  spec.require_paths = ["lib"]
  spec.extensions    = ["ext/ruby-sfml/extconf.rb"]

  spec.add_dependency "ffi", "~> 1.16"

  spec.add_development_dependency "rake",  "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "rdoc",  "~> 7.0"
end
