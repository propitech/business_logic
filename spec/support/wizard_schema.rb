# frozen_string_literal: true

# In-memory database + schema backing the WizardStepState / Wizard specs.
# The host app owns this table in real use (via the
# business_logic:wizard:install generator); here we materialise an
# equivalent table so the AR-backed model and engine can be exercised.

require "active_record"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  create_table :wizard_step_states do |t|
    t.string :subject_type, null: false
    t.bigint :subject_id, null: false
    t.string :wizard_key, null: false
    t.string :step_name, null: false
    t.datetime :succeeded_at
    t.datetime :dismissed_at
    t.json :error
    t.integer :attempts, null: false, default: 0
    t.timestamps
  end
  add_index :wizard_step_states, %i[subject_type subject_id wizard_key step_name], unique: true

  create_table :wizard_test_subjects
end

require "business_logic/wizard_step_state"

# A minimal AR record standing in as a polymorphic wizard subject.
class WizardTestSubject < ActiveRecord::Base
end

RSpec.configure do |config|
  # Roll back each `:db`-tagged example so the in-memory rows don't leak
  # between examples.
  config.around(:each, :db) do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
