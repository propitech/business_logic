# frozen_string_literal: true

module BusinessLogic
  module Matchers
    # Matcher for failure on contract and operation validations
    # @example
    #   contract = Contract.new.call(params: {})
    #   expect(contract).to fail_validation.with_error(message: "is missing")
    class FailureMatcher
      include RSpec::Matchers::Composable
      include Dry::Monads::Result::Mixin

      def matches?(actual)
        @actual = actual
        @monad = actual.is_a?(Dry::Validation::Result) ? actual.to_monad : actual

        @failed_reason = catch :failed do
          match_a_failure?
          match_the_error?
        end

        !@failed_reason
      end

      def with_error(error)
        @error = error
        self
      end

      def failure_message
        case failed_reason
        when :not_a_failure
          not_a_failure_message
        when :different_error
          different_error_message
        end
      end

      private

      attr_reader :actual, :failed_reason, :error, :monad

      def match_a_failure?
        throw(:failed, :not_a_failure) unless monad.is_a?(Failure)
      end

      def match_the_error?
        return false unless error

        throw(:failed, :different_error) unless error === actual_failure
      end

      def not_a_failure_message
        "expect #{actual.inspect} to be a Failure"
      end

      def different_error_message
        "expect to fail with #{error.inspect} but failed with #{actual_failure.inspect} instead."
      end

      def actual_failure
        case actual
        in Dry::Validation::Result
          actual.errors.to_hash
        in Failure(_ => a)
          a
        end
      end
    end
  end
end
