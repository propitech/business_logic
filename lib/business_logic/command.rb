# frozen_string_literal: true

require_relative "base_command"

module BusinessLogic
  # Batteries-included Command base class. Inherits from
  # {BaseCommand} (the bare class) and extends both
  # {Command::DependencyInjection} and {Command::FormBinding} so
  # every subclass gets `.dependency`, `.with`, and `.bind_form`
  # out of the box. The install template's `ApplicationCommand`
  # subclasses this directly:
  #
  #   class ApplicationCommand < BusinessLogic::Command
  #   end
  #
  # Apps that want a stricter base — no DI, no form binding —
  # subclass {Command::Base} (alias for {BaseCommand}) instead and
  # `extend` the mixins per command.
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

BusinessLogic::Command.extend(BusinessLogic::Command::DependencyInjection)
BusinessLogic::Command.extend(BusinessLogic::Command::FormBinding)
