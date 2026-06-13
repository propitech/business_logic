# frozen_string_literal: true

require "spec_helper"
require "generators/business_logic/wizard_install/wizard_install_generator"

RSpec.describe BusinessLogic::WizardInstallGenerator do
  setup_default_destination

  before { run_generator }

  def migration_paths
    Dir["#{destination_root}/db/migrate/*_create_wizard_step_states.rb"]
  end

  def migration_body
    path = migration_paths.first
    path ? File.read(path) : ""
  end

  it "creates a timestamped create_wizard_step_states migration" do
    expect(migration_paths).not_to be_empty
  end

  describe "the generated migration" do
    it "creates the table with a polymorphic subject", :aggregate_failures do
      expect(migration_body).to include("create_table :wizard_step_states")
      expect(migration_body).to include("t.references :subject, polymorphic: true, null: false")
    end

    it "carries the step + dismissal columns", :aggregate_failures do
      expect(migration_body).to include("t.string :wizard_key, null: false")
      expect(migration_body).to include("t.string :step_name, null: false")
      expect(migration_body).to include("t.datetime :succeeded_at")
      expect(migration_body).to include("t.datetime :dismissed_at")
      expect(migration_body).to include("t.integer :attempts, null: false, default: 0")
    end

    it "adds the unique index over (subject, wizard, step)" do
      expect(migration_body)
        .to include("%i[subject_type subject_id wizard_key step_name]")
        .and include("unique: true")
    end

    it "stamps the migration with the ActiveRecord version" do
      expect(migration_body).to match(/ActiveRecord::Migration\[\d+\.\d+\]/)
    end
  end
end
