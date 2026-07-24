# frozen_string_literal: true

module BusinessLogic
  class Command
    # A default `#validate` for contract-backed commands: runs the
    # command's `contract` over `attrs.to_h` and returns
    # `Success(validated_hash)` / `Failure(errors_hash)`.
    #
    # It assumes the host command declares both `attrs` (the raw
    # input, anything answering `#to_h`) and `contract` (usually a
    # `dependency` defaulting to the command's `Dry::Validation`
    # contract). A command whose contract call is non-standard — a
    # different input shape, or a `Success` wrapping the raw result
    # rather than its hash — overrides `#validate`.
    #
    #     class Commands::CreateUser < ApplicationCommand
    #       option     :attrs
    #       dependency :contract, default: -> { Contracts::CreateUser.new }
    #
    #       def execute
    #         validated = yield validate
    #         persist(validated)
    #       end
    #     end
    #
    # `BusinessLogic::Command` includes this by default.
    module ContractValidation
      private

      def validate
        result = contract.call(attrs.to_h)
        result.success? ? Success(result.to_h) : Failure(result.errors.to_h)
      end
    end
  end
end
