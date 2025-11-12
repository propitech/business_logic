# frozen_string_literal: true

require_relative "../helper"

module BusinessLogic
  # Generator for creating a new operation
  class OperationGenerator < Rails::Generators::NamedBase
    include Helper

    def generate_operation_files
      template "operation.rb.erb.tt", "#{install_path}/#{file_path}.rb"
      template "operation_spec.rb.erb.tt", "#{tests_path}/#{file_path}_spec.rb"
    end
  end
end
