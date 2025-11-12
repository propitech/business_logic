# frozen_string_literal: true

module BusinessLogic
  # Rails Railtie for BusinessLogic
  class Railtie < Rails::Railtie
    config.business_logic = ActiveSupport::OrderedOptions.new.merge({
      install_dir: "app/business_logic",
      test_dir: "spec/business_logic"
    })
  end
end
