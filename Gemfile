# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in ps-commons.gemspec
gemspec

group :development, :test do
  gem 'guard-bundler'
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'rake'
  gem 'rake-compiler', require: false
  gem 'rspec', '~> 3.0'
  gem 'rubocop'
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', require: false
  gem 'sqlite3', '~> 1.4.2' # seems to be the correct version for Rails 4 Active Record
end

group :test do
  gem 'simplecov', require: false
end
