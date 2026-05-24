# frozen_string_literal: true

require "spec_helper"
require "business_logic/form"

# Specs for required-field inference on BusinessLogic::Form.
#
# Source of truth is the dry-validation Contract bound to a Form by
# convention (Forms::Foo::BarForm -> Contracts::Foo::BarContract) or
# by explicit `validates_with_contract` declaration.
#
# All examples are skipped until the matching implementation step
# (see docs/agents-plans/0001-required-field-inference.md §Sequencing).
# Once each step lands, real assertions replace the `skip` calls;
# the disable below is removed by step 7 at the latest.
module ContractConventionSpec
  module Contracts
    module Users
      class BasicInfoContract < Dry::Validation::Contract
        params do
          required(:first_name).filled(:string)
          optional(:nickname).filled(:string)
        end
      end
    end
  end

  module Forms
    module Users
      class BasicInfoForm < BusinessLogic::Form
        attribute :first_name, :string
        attribute :nickname, :string
      end

      class OrphanForm < BusinessLogic::Form
        attribute :anything, :string
      end

      class ExplicitForm < BusinessLogic::Form
        validates_with_contract ContractConventionSpec::Contracts::Users::BasicInfoContract
        attribute :first_name, :string
      end
    end
  end
end

RSpec.describe BusinessLogic::Form do
  describe ".contract_class" do
    it "resolves the sibling Contract via the Forms:: -> Contracts:: convention" do
      expect(ContractConventionSpec::Forms::Users::BasicInfoForm.contract_class)
        .to eq(ContractConventionSpec::Contracts::Users::BasicInfoContract)
    end

    it "returns nil when no matching Contract constant exists" do
      expect(ContractConventionSpec::Forms::Users::OrphanForm.contract_class).to be_nil
    end

    it "honours the explicit binding when validates_with_contract is set" do
      expect(ContractConventionSpec::Forms::Users::ExplicitForm.contract_class)
        .to eq(ContractConventionSpec::Contracts::Users::BasicInfoContract)
    end
  end

  describe ".required_attributes" do
    it "lists every top-level required(...) key from the bound contract" do
      expect(ContractConventionSpec::Forms::Users::BasicInfoForm.required_attributes)
        .to include("first_name")
    end

    it "excludes optional(...) keys" do
      expect(ContractConventionSpec::Forms::Users::BasicInfoForm.required_attributes)
        .not_to include("nickname")
    end

    it "returns an empty set when no contract is resolvable" do
      expect(ContractConventionSpec::Forms::Users::OrphanForm.required_attributes).to be_empty
    end

    it "returns an empty set when probing the contract raises ArgumentError or NoMethodError" do
      uninstantiable = Class.new do
        def self.new(*) = raise ArgumentError, "contract takes arguments"
      end
      form = Class.new(BusinessLogic::Form) do
        validates_with_contract uninstantiable
      end
      expect(form.required_attributes).to be_empty
    end
  end

  describe ".attribute_required?" do
    let(:form) { ContractConventionSpec::Forms::Users::BasicInfoForm }

    it "returns true for required keys" do
      expect(form.attribute_required?(:first_name)).to be true
    end

    it "returns false for optional keys" do
      expect(form.attribute_required?(:nickname)).to be false
    end
  end

  describe "#required?" do
    let(:form) { ContractConventionSpec::Forms::Users::BasicInfoForm.new }

    it "delegates to the class-level attribute_required? for required keys" do
      expect(form.required?(:first_name)).to be true
    end

    it "delegates to the class-level attribute_required? for optional keys" do
      expect(form.required?(:nickname)).to be false
    end
  end

  describe "ActiveModel fallback" do
    let(:form_class) do
      Class.new(BusinessLogic::Form) do
        def self.name = "TopLevel::PresenceOnlyForm"

        attribute :nickname, :string
        validates :nickname, presence: true
      end
    end

    it "still reports required when an attribute has a presence validator and no contract is bound" do
      expect(form_class.attribute_required?(:nickname)).to be true
    end

    it "stays false for attributes with no validator and no contract" do
      expect(form_class.attribute_required?(:other)).to be false
    end
  end

  describe "memoisation" do
    let(:contract) do
      Class.new(Dry::Validation::Contract) do
        params { required(:email).filled(:string) }
      end
    end
    let(:form) do
      bound = contract
      Class.new(BusinessLogic::Form) do
        validates_with_contract bound
        attribute :email, :string
      end
    end

    it "introspects the contract only once per form class" do
      allow(contract).to receive(:new).and_call_original
      3.times { form.required_attributes }
      expect(contract).to have_received(:new).once
    end
  end
end
