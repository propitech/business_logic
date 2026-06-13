# frozen_string_literal: true

require "rails/generators/base"
require "rails/generators/migration"
require "rails/generators/active_record"

module BusinessLogic
  # Installs the `wizard_step_states` table that backs
  # BusinessLogic::Wizard / BusinessLogic::WizardStepState. Run it once in
  # a host app, then subclass BusinessLogic::Wizard per flow.
  #
  #   bin/rails generate business_logic:wizard_install
  class WizardInstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_root File.expand_path("templates", __dir__)

    def self.next_migration_number(dirname)
      ActiveRecord::Generators::Base.next_migration_number(dirname)
    end

    def create_wizard_step_states_migration
      migration_template "create_wizard_step_states.rb.tt",
        "db/migrate/create_wizard_step_states.rb"
    end

    private

    def migration_version
      "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
    end
  end
end
