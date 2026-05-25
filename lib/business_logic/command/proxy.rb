# frozen_string_literal: true

module BusinessLogic
  class Command
    # Per-call option-override proxy built by `Command.with(...)`.
    # Captures a command class plus a hash of `option` overrides,
    # then on `#call(*params, **keyword_params)` instantiates the
    # command with `(*params, **keyword_params, **overrides)` and
    # invokes it. Overrides land last so they win over any matching
    # call-site kwarg.
    #
    # Marked as a private constant on {Command} — callers reach it
    # through `Command.with(...)`, not by name.
    class Proxy
      def initialize(command_class, option_overrides)
        @command_class = command_class
        @option_overrides = option_overrides
      end

      def call(*params, **keyword_params)
        @command_class.new(*params, **keyword_params, **@option_overrides).call
      end
    end
    private_constant :Proxy
  end
end
