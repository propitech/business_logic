# frozen_string_literal: true

require_relative "business_logic/version"
require "business_logic/railtie" if defined?(Rails::Railtie)

module BusinessLogic
  class Error < StandardError; end
  # Your code goes here...
end
