# frozen_string_literal: true

require_relative "../helper"

module BusinessLogic
  # Generator for creating a new form object
  class FormGenerator < Rails::Generators::NamedBase
    include Helper

    def generate_form_files
      template "form.rb.erb.tt", "#{install_path}/#{file_path}.rb"
      template "form_spec.rb.erb.tt", "#{tests_path}/#{file_path}_spec.rb"
    end
  end
end
