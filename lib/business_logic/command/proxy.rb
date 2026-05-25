# frozen_string_literal: true

module BusinessLogic
  class Command
    # Per-call option-override proxy built by `Command.with(...)`.
    # Captures a callable (command class or another proxy) plus a
    # hash of `option` overrides, then on
    # `#call(*params, **keyword_params)` forwards to the callable
    # with `(*params, **keyword_params, **overrides)`. Overrides
    # land last so they win over any matching call-site kwarg.
    #
    # Includes {Chainable} so further `.with` or `.bind_form`
    # composition is supported in either order.
    #
    # Marked as a private constant on {Command} — callers reach it
    # through `Command.with(...)`, not by name.
    class Proxy
      include Chainable

      def initialize(callable, option_overrides, root_class:)
        @callable = callable
        @option_overrides = option_overrides
        @root_class = root_class
      end

      def call(*params, **keyword_params)
        @callable.call(*params, **keyword_params, **@option_overrides)
      end
    end
    private_constant :Proxy
  end
end
