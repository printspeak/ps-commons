# frozen_string_literal: true

require 'pry'
require 'bundler/setup'
require 'simplecov'
require 'sqlite3'

# require "shoulda/matchers/integrations/rspec"

SimpleCov.start

require 'ps/commons'

Dir.chdir('spec') do
  Dir['support/**/*.rb'].sort.each { |file| require_relative file }
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'
  config.filter_run_when_matching :focus

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
