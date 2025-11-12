# frozen_string_literal: true

if ENV["CI"]
  require "simplecov"
  require "simplecov_json_formatter"
  require "simplecov-cobertura"

  formatters = [
    SimpleCov::Formatter::JSONFormatter,
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::CoberturaFormatter
  ]
  SimpleCov.start "rails" do
    formatter SimpleCov::Formatter::MultiFormatter.new formatters
    add_filter "/spec/"
  end
end
