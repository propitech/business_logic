# frozen_string_literal: true

require_relative "../helper"

module BusinessLogic
  # Generator for installing BusinessLogic templates
  class InstallGenerator < Rails::Generators::Base
    include Helper

    def install
      copy_files
      install_gems
    end

    private

    def copy_files
      copy_file "application_operation.rb.tt", "#{install_path}/application_operation.rb"
      copy_file "application_contract.rb.tt", "#{install_path}/application_contract.rb"
      copy_file "spec_generators_helper.rb.tt", "#{tests_path}/generators_helper.rb"
    end

    def install_gems
      gem "ammeter", "~> 1.1", group: :test
      gem "dry-initializer", "~> 3.1"
      gem "dry-operation", "~> 1.0"
      gem "dry-validation", "~> 1.10"
    end
  end
end
