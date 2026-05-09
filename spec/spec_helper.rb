$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "sfml"
require "tmpdir"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random
  Kernel.srand config.seed

  # Audio specs go through CoreAudio on macOS, where the OpenAL
  # backend occasionally hangs an entire example group (per CSFML's
  # own track record on darwin runners). Tag every spec under
  # `spec/sfml/audio/` with `:audio` and skip the group by default
  # on darwin. Opt-in with `bundle exec rspec --tag audio`.
  config.define_derived_metadata(file_path: %r{/spec/sfml/audio/}) do |meta|
    meta[:audio] = true
  end

  if RUBY_PLATFORM =~ /darwin/
    config.filter_run_excluding(audio: true)
  end
end
