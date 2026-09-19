# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in business_logic.gemspec
gemspec

gem "rake", "~> 13.4"

gem "ammeter", "~> 1.1"
gem "dry-monads", "~> 1.11"
gem "dry-operation", "~> 1.1"
gem "dry-validation", "~> 1.11"
# json 3.0 made JSON.parse keyword-only and activesupport 8.1.3.1 still passes
# its options hash positionally (rails/rails#58601, unreleased). Drop the cap
# once a Rails release ships that fix.
gem "json", "< 3"
gem "rails", ">= 7.0"
gem "reek", "~> 6.5"
gem "rspec", "~> 3.0"
gem "rspec_junit_formatter"
gem "rspec-rails", "~> 8.0"
gem "rubocop", "~> 1.91"
gem "rubocop-rake", "~> 0.7"
gem "rubocop-rspec", "~> 3.10"
gem "rubocop-rspec_rails"
gem "rubocop-thread_safety", "~> 0.8.0"
gem "simplecov", require: false
gem "simplecov-cobertura", require: false
gem "simplecov_json_formatter", require: false
gem "sqlite3", "~> 2.9" # in-memory DB for the WizardStepState AR specs
