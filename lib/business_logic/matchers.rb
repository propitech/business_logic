# frozen_string_literal: true

require "dry-monads"
require "dry-validation"
require "business_logic/matchers/success_matcher"
require "business_logic/matchers/failure_matcher"

Dry::Validation.load_extensions(:monads)

module BusinessLogic
  module Matchers # :nodoc:
    def succeed_contract
      SuccessMatcher.new
    end
    alias succeed_validation succeed_contract
    alias succeed_operation succeed_contract

    def fail_contract
      FailureMatcher.new
    end
    alias fail_validation fail_contract
    alias fail_operation fail_contract
  end
end
