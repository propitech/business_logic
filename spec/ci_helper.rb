# frozen_string_literal: true

if ENV["CI"]
  require "simplecov"
  require "simplecov-cobertura"

  formatters = [
    SimpleCov::Formatter::JSONFormatter,
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::CoberturaFormatter
  ]
  SimpleCov.start do
    cover "lib/**/*.rb"
    formatter SimpleCov::Formatter::MultiFormatter.new formatters
    skip "/spec/"
    # The gemspec requires version.rb before SimpleCov starts, so Coverage
    # never sees it and cover would list it at 0%.
    skip "lib/business_logic/version.rb"
  end
end
