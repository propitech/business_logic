# frozen_string_literal: true

require "spec_helper"
require "dry/monads"

RSpec.describe BusinessLogic::Wizard, :db do
  include Dry::Monads[:result]

  subject(:wizard) { wizard_class.new(owner) }

  let(:owner) { WizardTestSubject.create! }
  # Call counter so specs can assert when a step block actually runs.
  let(:calls) { Hash.new(0) }
  # Per-step results, mutable so a spec can flip one to a Failure.
  let(:results) { {one: Success(:a), two: Success(:b), three: Success(:c)} }

  let(:wizard_class) do
    calls_ref = calls
    results_ref = results

    Class.new(described_class) do
      step(:one) do |input|
        calls_ref[:one] += 1
        input.nil? ? results_ref[:one] : Success(input)
      end
      step(:two) do
        calls_ref[:two] += 1
        results_ref[:two]
      end
      step(:three) do
        calls_ref[:three] += 1
        results_ref[:three]
      end
    end
  end

  before { stub_const("ExampleWizard", wizard_class) }

  def complete(*names)
    names.each { |name| wizard.process(name) }
  end

  describe ".step" do
    it "preserves declaration order" do
      expect(wizard_class.step_names).to eq(%i[one two three])
    end

    it "rejects a duplicate step name" do
      expect { wizard_class.step(:one) { Success() } }.to raise_error(ArgumentError, /already declared/)
    end
  end

  describe ".wizard_key" do
    it "is the class name underscored" do
      expect(wizard_class.wizard_key).to eq("example_wizard")
    end
  end

  describe "#process" do
    it "runs the first step and returns its result" do
      expect(wizard.process(:one)).to eq(Success(:a))
    end

    it "passes input to the step block" do
      expect(wizard.process(:one, "payload")).to eq(Success("payload"))
    end

    it "records success in the database", :aggregate_failures do
      wizard.process(:one)
      state = BusinessLogic::WizardStepState.sole
      expect(state).to have_attributes(
        wizard_key: "example_wizard", step_name: "one", attempts: 1, succeeded?: true
      )
    end

    it "raises on an unknown step" do
      expect { wizard.process(:nope) }.to raise_error(ArgumentError, /unknown step/)
    end

    context "when a prerequisite is incomplete" do
      it "returns a prerequisites Failure" do
        expect(wizard.process(:two)).to eq(Failure(prerequisites: %i[one]))
      end

      it "does not run the step block" do
        wizard.process(:two)
        expect(calls[:two]).to eq(0)
      end

      it "records nothing" do
        wizard.process(:two)
        expect(BusinessLogic::WizardStepState.count).to eq(0)
      end
    end

    context "when prerequisites are met" do
      before { complete(:one) }

      it "runs the next step" do
        expect(wizard.process(:two)).to eq(Success(:b))
      end
    end

    context "when the step already succeeded" do
      before { complete(:one) }

      it "skips the block and reports skipped" do
        expect(wizard.process(:one)).to eq(Success(:skipped))
      end

      it "does not re-run the block" do
        wizard.process(:one)
        expect(calls[:one]).to eq(1)
      end

      it "re-runs the block via reprocess" do
        wizard.reprocess(:one)
        expect(calls[:one]).to eq(2)
      end
    end

    context "when the step fails" do
      before { results[:one] = Failure(name: ["is missing"]) }

      it "returns the Failure" do
        expect(wizard.process(:one)).to eq(Failure(name: ["is missing"]))
      end

      it "leaves the step incomplete" do
        wizard.process(:one)
        expect(wizard.step_succeeded?(:one)).to be(false)
      end

      it "allows a later successful retry" do
        wizard.process(:one)
        results[:one] = Success(:a)
        expect(wizard.process(:one)).to eq(Success(:a))
      end
    end
  end

  describe "#furthest_incomplete" do
    it "is the first step before anything runs" do
      expect(wizard.furthest_incomplete).to eq(:one)
    end

    it "advances as steps complete" do
      complete(:one, :two)
      expect(wizard.furthest_incomplete).to eq(:three)
    end

    it "is the last step once everything is done" do
      complete(:one, :two, :three)
      expect(wizard.furthest_incomplete).to eq(:three)
    end
  end

  describe "#completed?" do
    it "is false until every step has succeeded" do
      complete(:one, :two)
      expect(wizard).not_to be_completed
    end

    it "is true once every step has succeeded" do
      complete(:one, :two, :three)
      expect(wizard).to be_completed
    end
  end
end
