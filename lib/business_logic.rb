# frozen_string_literal: true

require_relative "business_logic/version"
require_relative "business_logic/railtie" if defined?(Rails::Railtie)
require_relative "business_logic/form"
require_relative "business_logic/command"

module BusinessLogic # :nodoc:
end
