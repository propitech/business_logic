# frozen_string_literal: true

require_relative "base_command"

module BusinessLogic
  # Batteries-included Command base class. Inherits from
  # {BaseCommand} (the bare class) and mixes in
  # {Command::DependencyInjection}, {Command::FormBinding},
  # {Command::RescueFrom}, and {Command::ContractValidation} so every
  # subclass gets `.dependency`, `.with`, `.bind_form`,
  # `.rescue_from`, and a default `#validate` out of the box. The
  # install template's `ApplicationCommand` subclasses this directly:
  #
  #   class ApplicationCommand < BusinessLogic::Command
  #   end
  #
  # Apps that want a stricter base — no DI, no form binding, no
  # rescue mapping — subclass {Command::Base} (alias for
  # {BaseCommand}) instead and mix the extensions in per command.
  class Command < BaseCommand
  end

  # Public alias for {BaseCommand}. Reach for it when you need the
  # stripped-down base (no DI, no form binding).
  Command::Base = BaseCommand
end

require_relative "command/chainable"
require_relative "command/proxy"
require_relative "command/form_binding_proxy"
require_relative "command/dependency_injection"
require_relative "command/form_binding"
require_relative "command/rescue_from"
require_relative "command/contract_validation"

BusinessLogic::Command.extend(BusinessLogic::Command::DependencyInjection)
BusinessLogic::Command.extend(BusinessLogic::Command::FormBinding)
# Extending RescueFrom also includes its `#call` wrapper, which is
# what turns a declared exception into a `Failure`.
BusinessLogic::Command.extend(BusinessLogic::Command::RescueFrom)
BusinessLogic::Command.include(BusinessLogic::Command::ContractValidation)
