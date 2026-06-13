# frozen_string_literal: true

require "active_record"

module BusinessLogic
  # Per-step success log backing {BusinessLogic::Wizard}. One row per
  # (subject, wizard, step); `succeeded_at` marks completion. Operational
  # state — not audit-worthy.
  #
  # The table is host-owned (install it with the
  # `business_logic:wizard:install` generator); this model maps onto it.
  class WizardStepState < ActiveRecord::Base
    self.table_name = "wizard_step_states"

    belongs_to :subject, polymorphic: true

    # Reserved step_name for the wizard-level dismissal ("Don't remind me
    # anymore"). It belongs to the wizard as a whole, not to any declared
    # step, so it stays out of the step_name space {Wizard} iterates —
    # completion logic never sees this row.
    DISMISSAL_STEP = "__dismissed__"

    def self.for(subject:, wizard_key:, step_name:)
      find_or_initialize_by(subject:, wizard_key:, step_name: step_name.to_s)
    end

    # Stamp the wizard-level dismissal marker. Idempotent: keeps the first
    # dismissal time on repeat calls.
    def self.dismiss!(subject:, wizard_key:)
      record = self.for(subject:, wizard_key:, step_name: DISMISSAL_STEP)
      record.update!(dismissed_at: Time.current) unless record.dismissed?
      record
    end

    def self.dismissed?(subject:, wizard_key:)
      where(subject:, wizard_key:, step_name: DISMISSAL_STEP)
        .where.not(dismissed_at: nil)
        .exists?
    end

    def succeeded?
      succeeded_at.present?
    end

    def dismissed?
      dismissed_at.present?
    end

    # Record one execution attempt's outcome and persist. Returns the
    # result so the caller can keep threading the monad.
    def record(result)
      self.attempts += 1
      result.success? ? mark_succeeded : capture(result.failure)
      save!
      result
    end

    # Clear the success marker so the step runs again on the next attempt.
    def reopen
      update!(succeeded_at: nil)
    end

    private

    def mark_succeeded
      assign_attributes(succeeded_at: Time.current, error: nil)
    end

    def capture(failure)
      self.error = failure
    end
  end
end
