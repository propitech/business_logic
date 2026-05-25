# frozen_string_literal: true

require_relative "command/base"

module BusinessLogic
  # Batteries-included Command base class. Inherits from
  # {CommandBase} (the bare class) and extends
  # {Command::DependencyInjection} so every subclass gets
  # `.dependency` and `.with` out of the box. The install
  # template's `ApplicationCommand` subclasses this directly:
  #
  #   class ApplicationCommand < BusinessLogic::Command
  #   end
  #
  # Apps that want a stricter base — no DI — subclass
  # {Command::Base} (alias for {CommandBase}) instead and `extend`
  # the mixin per command.
  class Command < CommandBase
  end

  # Public alias for {CommandBase}. Reach for it when you need the
  # stripped-down base (no DI).
  Command::Base = CommandBase
end

require_relative "command/proxy"
require_relative "command/dependency_injection"

BusinessLogic::Command.extend(BusinessLogic::Command::DependencyInjection)
