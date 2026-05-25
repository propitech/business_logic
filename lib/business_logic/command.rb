# frozen_string_literal: true

require_relative "command/base"

module BusinessLogic
  # Batteries-included Command base class. Inherits from
  # {CommandBase} (the bare class) and extends both
  # {Command::DependencyInjection} and {Command::FormBinding} so
  # every subclass gets `.dependency`, `.with`, and `.bind_form`
  # out of the box. The install template's `ApplicationCommand`
  # subclasses this directly:
  #
  #   class ApplicationCommand < BusinessLogic::Command
  #   end
  #
  # Apps that want a stricter base — no DI, no form binding —
  # subclass {Command::Base} (alias for {CommandBase}) instead and
  # `extend` the mixins per command.
  class Command < CommandBase
  end

  # Public alias for {CommandBase}. Reach for it when you need the
  # stripped-down base (no DI, no form binding).
  Command::Base = CommandBase
end

require_relative "command/chainable"
require_relative "command/proxy"
require_relative "command/form_binding_proxy"
require_relative "command/dependency_injection"
require_relative "command/form_binding"

BusinessLogic::Command.extend(BusinessLogic::Command::DependencyInjection)
BusinessLogic::Command.extend(BusinessLogic::Command::FormBinding)
