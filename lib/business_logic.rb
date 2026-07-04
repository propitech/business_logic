# frozen_string_literal: true

require_relative "business_logic/version"
require_relative "business_logic/railtie" if defined?(Rails::Railtie)
require_relative "business_logic/form"
require_relative "business_logic/command"
require_relative "business_logic/wizard"
require_relative "business_logic/wizard_step_state" if defined?(ActiveRecord::Base)

module BusinessLogic # :nodoc:
end

require_relative "business_logic/rubocop"
