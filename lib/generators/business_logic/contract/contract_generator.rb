# frozen_string_literal: true

require_relative "../helper"

module BusinessLogic
  # Generator for creating a new contract
  class ContractGenerator < Rails::Generators::NamedBase
    include Helper

    source_root File.expand_path("templates", __dir__)

    def generate_operation_files
      template "contract.rb.erb.tt", "#{install_path}/#{file_path}.rb"
      template "contract_spec.rb.erb.tt", "#{tests_path}/#{file_path}_spec.rb"
    end
  end
end
