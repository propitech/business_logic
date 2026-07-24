# frozen_string_literal: true

require "spec_helper"
require "business_logic/command"
require "business_logic/matchers"

RSpec.describe BusinessLogic::Command::ContractValidation do
  include BusinessLogic::Matchers

  let(:contract_class) do
    Class.new(Dry::Validation::Contract) do
      params do
        required(:email).filled(:string)
      end
    end
  end

  let(:command_class) do
    Class.new(BusinessLogic::Command::Base) do
      include BusinessLogic::Command::ContractValidation

      option :attrs
      option :contract

      def execute = validate
    end
  end

  describe "#validate" do
    it "returns the validated attributes on Success" do
      result = command_class.call(attrs: {email: "ada@example.com"}, contract: contract_class.new)
      expect(result).to succeed_command.with_value(email: "ada@example.com")
    end

    it "returns the contract errors on Failure" do
      result = command_class.call(attrs: {}, contract: contract_class.new)
      expect(result).to fail_command.with_error(email: ["is missing"])
    end

    it "accepts any attrs answering #to_h" do
      attrs = Struct.new(:email).new("ada@example.com")
      result = command_class.call(attrs: attrs, contract: contract_class.new)
      expect(result).to succeed_command.with_value(email: "ada@example.com")
    end

    it "is private, so it stays an implementation detail of #execute" do
      command = command_class.new(attrs: {}, contract: contract_class.new)
      expect { command.validate }.to raise_error(NoMethodError, /private method/)
    end

    it "is overridable per command" do
      overriding = Class.new(command_class) do
        private def validate = Success(:overridden)
      end
      expect(overriding.call(attrs: {}, contract: contract_class.new))
        .to succeed_command.with_value(:overridden)
    end
  end

  describe "opt-in" do
    it "is pre-included in BusinessLogic::Command" do
      expect(BusinessLogic::Command.private_instance_methods).to include(:validate)
    end

    it "is not available on bare Command::Base subclasses" do
      expect(BusinessLogic::Command::Base.private_instance_methods).not_to include(:validate)
    end
  end
end
