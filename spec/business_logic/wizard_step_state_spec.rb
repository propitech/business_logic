# frozen_string_literal: true

require "spec_helper"
require "dry/monads"

RSpec.describe BusinessLogic::WizardStepState, :db do
  include Dry::Monads[:result]

  let(:owner) { WizardTestSubject.create! }
  let(:wizard_key) { "wizards/example" }

  def state_for(step_name)
    described_class.for(subject: owner, wizard_key:, step_name:)
  end

  describe ".for" do
    it "initializes a row scoped to subject + wizard + step", :aggregate_failures do
      state = state_for("one")
      expect(state).to have_attributes(subject: owner, wizard_key:, step_name: "one")
      expect(state).not_to be_succeeded
    end

    it "returns the existing row on a second lookup once persisted" do
      state_for("one").save!
      expect { state_for("one") }.not_to change(described_class, :count).from(1)
    end
  end

  describe "#record" do
    it "marks succeeded, clears the error, and returns the result", :aggregate_failures do
      state = state_for("one")
      result = state.record(Success(:ok))
      expect(result).to eq(Success(:ok))
      expect(state.reload).to have_attributes(succeeded?: true, attempts: 1, error: nil)
    end

    it "captures the failure payload and leaves the step open", :aggregate_failures do
      state = state_for("one")
      state.record(Failure(name: ["is missing"]))
      expect(state.reload).to have_attributes(succeeded?: false, attempts: 1, error: {"name" => ["is missing"]})
    end

    it "counts attempts across calls" do
      state = state_for("one")
      state.record(Failure(:nope))
      state.record(Success(:ok))
      expect(state.attempts).to eq(2)
    end
  end

  describe "#reopen" do
    it "clears the success marker" do
      state = state_for("one")
      state.record(Success(:ok))
      state.reopen
      expect(state).not_to be_succeeded
    end
  end

  describe "wizard-level dismissal" do
    it ".dismissed? is false before any dismissal" do
      expect(described_class.dismissed?(subject: owner, wizard_key:)).to be(false)
    end

    it ".dismiss! writes the reserved marker row and flips .dismissed?", :aggregate_failures do
      record = described_class.dismiss!(subject: owner, wizard_key:)
      expect(record.step_name).to eq(described_class::DISMISSAL_STEP)
      expect(described_class.dismissed?(subject: owner, wizard_key:)).to be(true)
    end

    it ".dismiss! is idempotent and keeps the first dismissal time" do
      first = described_class.dismiss!(subject: owner, wizard_key:).dismissed_at
      expect(described_class.dismiss!(subject: owner, wizard_key:).dismissed_at.to_i).to eq(first.to_i)
    end

    it ".dismissed? is scoped per wizard" do
      described_class.dismiss!(subject: owner, wizard_key:)
      expect(described_class.dismissed?(subject: owner, wizard_key: "wizards/other")).to be(false)
    end
  end
end
