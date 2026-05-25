# frozen_string_literal: true

require_relative "../helper"

module BusinessLogic
  # Generator for creating a new command
  class CommandGenerator < Rails::Generators::NamedBase
    include Helper

    def generate_command_files
      template "command.rb.erb.tt", "#{install_path}/#{file_path}.rb"
      template "command_spec.rb.erb.tt", "#{tests_path}/#{file_path}_spec.rb"
    end
  end
end
