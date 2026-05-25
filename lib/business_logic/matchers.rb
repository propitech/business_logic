# frozen_string_literal: true

require "dry-monads"
require "dry-validation"
require "business_logic/matchers/success_matcher"
require "business_logic/matchers/failure_matcher"

Dry::Validation.load_extensions(:monads)

module BusinessLogic
  # RSpec matchers for `Dry::Monads::Result` and
  # `Dry::Validation::Result`. Each name is a factory for the
  # corresponding matcher class — `expect(x).to succeed_contract`,
  # `expect(x).to fail_command.with_error(...)`, etc.
  #
  # The methods are declared as `module_function`s so they can be
  # called either as `BusinessLogic::Matchers.fail_contract` or
  # (after `include BusinessLogic::Matchers`) as `fail_contract`.
  # Aliases provide name variants per call-site convention
  # (`succeed_validation` for contracts, `succeed_operation` for
  # operations, `succeed_command` for commands).
  module Matchers
    def succeed_contract
      SuccessMatcher.new
    end
    alias succeed_validation succeed_contract
    alias succeed_operation succeed_contract
    alias succeed_command succeed_contract

    def fail_contract
      FailureMatcher.new
    end
    alias fail_validation fail_contract
    alias fail_operation fail_contract
    alias fail_command fail_contract

    module_function :succeed_contract, :succeed_validation, :succeed_operation, :succeed_command,
      :fail_contract, :fail_validation, :fail_operation, :fail_command
  end
end
