# frozen_string_literal: true

require "dry-initializer"
require "dry/monads"
require "dry/monads/do"

module BusinessLogic
  # Bare {Command} base class — `param`, `option`, single-shot
  # `#call`, plus the `AlreadyCalled` / `UnknownDependency` error
  # classes. No dependency-injection or form-binding DSL.
  #
  # Defined under the top-level name `BusinessLogic::CommandBase`
  # so that `BusinessLogic::Command` can inherit from it in
  # `command.rb`; the public alias `BusinessLogic::Command::Base`
  # is wired up there. Apps that want a stricter base — no `.with`,
  # no `.bind_form`, no `.dependency` — should subclass
  # `BusinessLogic::Command::Base` directly.
  #
  # @abstract Subclass and implement {#execute}.
  class CommandBase
    extend Dry::Initializer
    include Dry::Monads[:result, :do]

    # Raised when {#call} is invoked more than once on the same
    # instance. Commands are single-shot by design — construct a
    # new instance to re-run.
    class AlreadyCalled < StandardError; end

    # Raised by {Command::DependencyInjection#with} when an
    # override key is not a declared `dependency`. Defined here so
    # it is stable for `rescue` clauses regardless of which
    # extensions are mixed in.
    class UnknownDependency < ArgumentError; end

    # Sugar for `new(*params, **keyword_params).call`. Use when no
    # per-call dependency overrides are needed.
    def self.call(*params, **keyword_params)
      new(*params, **keyword_params).call
    end

    # Run the command. Raises {AlreadyCalled} on the second
    # invocation. Delegates to the subclass's {#execute}.
    #
    # @return [Dry::Monads::Result]
    def call
      raise AlreadyCalled, "#{self.class} already called" if @__called

      @__called = true
      execute
    end

    private

    # Abstract entry point. Subclasses override this and return a
    # `Dry::Monads::Result`. The base's {#call} wraps it with the
    # single-shot guard.
    #
    # @abstract
    # @return [Dry::Monads::Result]
    def execute
      raise NotImplementedError, "#{self.class} must implement #execute"
    end
  end
end
