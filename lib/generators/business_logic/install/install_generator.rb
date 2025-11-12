# frozen_string_literal: true

require_relative "../helper"

module BusinessLogic
  # Generator for installing BusinessLogic templates
  class InstallGenerator < Rails::Generators::Base
    include Helper

    def install
      copy_file "application_operation.rb.tt", "#{install_path}/application_operation.rb"
      copy_file "application_contract.rb.tt", "#{install_path}/application_contract.rb"
      copy_file "spec_generators_helper.rb.tt", "#{test_path}/generators_helper.rb"
    end
  end
end
