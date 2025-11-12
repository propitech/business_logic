# frozen_string_literal: true

require "business_logic"
require "rails"
# Pick the frameworks you want:
require "active_model"
# require "active_job/railtie"
# require "active_record/railtie"
# require "active_storage/engine"
require "action_controller"
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view"
# require "action_cable/engine"
require "rspec/rails"
require "ammeter/init"
dir = File.dirname(__FILE__)
Dir["#{dir}/support/**/*.rb"].sort_by(&:to_s).each { |f| require f }

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
