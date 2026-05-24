# frozen_string_literal: true

require "spec_helper"
require "business_logic/form"
require "business_logic/simple_form/required"

# Stand-in for the slice of SimpleForm::Inputs::Base the module
# touches. Avoids pulling simple_form as a runtime/dev dep just to
# exercise calculate_required.
class StubInput
  attr_reader :object, :attribute_name, :options

  def initialize(object:, attribute_name:, options: {})
    @object = object
    @attribute_name = attribute_name
    @options = options
  end

  def calculate_required
    :fell_through_to_super
  end
end

module SimpleFormRequiredSpec
  module Contracts
    module Users
      class ProfileContract < Dry::Validation::Contract
        params do
          required(:first_name).filled(:string)
          optional(:nickname).filled(:string)
        end
      end
    end
  end

  module Forms
    module Users
      class ProfileForm < BusinessLogic::Form
        attribute :first_name, :string
        attribute :nickname, :string
      end
    end
  end

  class PlainModel
    include ActiveModel::Model
  end
end

RSpec.describe BusinessLogic::SimpleForm::Required do
  let(:input_class) { Class.new(StubInput) { prepend BusinessLogic::SimpleForm::Required } }
  let(:form) { SimpleFormRequiredSpec::Forms::Users::ProfileForm.new }

  def build_input(object:, attribute_name:, options: {})
    input_class.new(object: object, attribute_name: attribute_name, options: options)
  end

  context "with a contract-backed BusinessLogic::Form" do
    it "returns true for required contract keys" do
      input = build_input(object: form, attribute_name: :first_name)
      expect(input.calculate_required).to be true
    end

    it "returns false for optional contract keys" do
      input = build_input(object: form, attribute_name: :nickname)
      expect(input.calculate_required).to be false
    end

    it "honours options[:required] = false override even when contract requires the key" do
      input = build_input(object: form, attribute_name: :first_name, options: {required: false})
      expect(input.calculate_required).to be false
    end

    it "honours options[:required] = true override on optional keys" do
      input = build_input(object: form, attribute_name: :nickname, options: {required: true})
      expect(input.calculate_required).to be true
    end
  end

  context "with a BusinessLogic::Form that has no resolvable contract" do
    let(:orphan_form) do
      Class.new(BusinessLogic::Form) do
        def self.name = "TopLevel::OrphanForm"

        attribute :anything, :string
      end.new
    end

    it "falls through to super" do
      input = build_input(object: orphan_form, attribute_name: :anything)
      expect(input.calculate_required).to eq(:fell_through_to_super)
    end
  end

  context "with a non-BusinessLogic object" do
    it "falls through to super" do
      input = build_input(object: SimpleFormRequiredSpec::PlainModel.new, attribute_name: :name)
      expect(input.calculate_required).to eq(:fell_through_to_super)
    end
  end
end
