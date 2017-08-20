# frozen_string_literal: true

require 'bundler/setup'
require_relative '../lib/lazy_lazer'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Enhancements for running single tests.
  config.filter_run_when_matching :focus
  config.default_formatter = 'doc' if config.files_to_run.one?

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
