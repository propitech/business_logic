# frozen_string_literal: true

module BusinessLogic
  module Matchers
    # Matcher for success on contract and operation validations
    # @example
    #   contract = Contract.new.call(params: {})
    #   expect(contract).to succeed_validation.with_value(user: { name: "John" }))
    class SuccessMatcher
      include RSpec::Matchers::Composable
      include Dry::Monads::Result::Mixin

      def matches?(actual)
        @actual = actual
        @monad = actual.is_a?(Dry::Validation::Result) ? actual.to_monad : actual

        @failed_reason = catch(:failed) do
          match_success?
          match_the_value?
        end

        !@failed_reason
      end

      def with_value(value)
        @value = value
        self
      end

      def failure_message
        case failed_reason
        when :not_a_success
          not_a_success_message
        when :different_value
          different_value_message
        end
      end

      private

      attr_reader :actual, :value, :failed_reason, :monad

      def match_success?
        throw(:failed, :not_a_success) unless monad.is_a?(Success)
      end

      def match_the_value?
        return false unless value

        throw(:failed, :different_value) unless value === success_value
      end

      def not_a_success_message
        "expect #{actual.inspect} to be a Success"
      end

      def different_value_message
        "expect to succeed with #{value.inspect} but succeeded with #{success_value.inspect} instead."
      end

      def success_value
        case monad
        in Success(Dry::Validation::Result => a)
          a.to_h
        else
          monad.value!
        end
      end
    end
  end
end
