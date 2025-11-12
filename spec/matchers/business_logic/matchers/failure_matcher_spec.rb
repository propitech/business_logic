# frozen_string_literal: true

require "spec_helper"
require "business_logic/matchers"

RSpec.describe BusinessLogic::Matchers::FailureMatcher do
  include Dry::Monads::Result::Mixin

  subject(:result) { matcher.matches?(actual) }

  let(:matcher_instance) { described_class.new }
  let(:matcher) { matcher_instance }
  let(:value) { nil }

  before { result }

  shared_examples "matching without error" do
    it { is_expected.to be_truthy }

    it "has no failure message" do
      expect(matcher.failure_message).to be_nil
    end
  end

  shared_examples "failing with error" do
    it { is_expected.to be_falsey }

    it "has a failure message" do
      expect(matcher.failure_message).to eq(expected_failure_message)
    end
  end

  shared_examples "it is a Failure" do
    context "without value given" do
      it_behaves_like "matching without error"
    end

    context "with correct value given" do
      let(:matcher) { matcher_instance.with_error(correct_value) }

      it_behaves_like "matching without error"
    end

    context "with incorrect value given" do
      let(:matcher) { matcher_instance.with_error(incorrect_value) }
      let(:expected_failure_message) do
        "expect to fail with #{incorrect_value.inspect} but failed with #{correct_value.inspect} instead."
      end

      it_behaves_like "failing with error"
    end
  end

  shared_examples "it is a Success" do
    let(:actual) { Success(correct_value) }
    let(:expected_failure_message) { "expect #{actual.inspect} to be a Failure" }

    context "without value given" do
      it_behaves_like "failing with error"
    end

    context "with correct value given" do
      let(:matcher) { matcher_instance.with_error(correct_value) }

      it_behaves_like "failing with error"
    end

    context "with incorrect value given" do
      let(:matcher) { matcher_instance.with_error(incorrect_value) }

      it_behaves_like "failing with error"
    end
  end

  context "when it is a monad" do
    it_behaves_like "it is a Failure" do
      let(:actual) { Failure(correct_value) }
      let(:incorrect_value) { :not_ok }
      let(:correct_value) { :ok }
    end

    it_behaves_like "it is a Success" do
      let(:actual) { Success(correct_value) }
      let(:incorrect_value) { :success }
      let(:correct_value) { :error }
    end
  end

  context "when it is a Dry::Validation::Result" do
    let(:contract_class) do
      Class.new(ApplicationContract) do
        params do
          required(:age).filled(:integer)
        end

        rule(:age) do
          key.failure("must be greater than 18 but was #{value}") if value < 18
        end
      end
    end

    it_behaves_like "it is a Success" do
      let(:actual) { contract_class.new.call(age: 22) }
      let(:incorrect_value) { {age: 30} }
      let(:correct_value) { {age: 22} }
    end

    it_behaves_like "it is a Failure" do
      let(:actual) { contract_class.new.call(age: 16) }
      let(:incorrect_value) { {age: 30} }
      let(:correct_value) { {age: ["must be greater than 18 but was 16"]} }
    end
  end
end
