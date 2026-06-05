# frozen_string_literal: true

require "dry-initializer"
require "dry/monads"
require "dry/monads/do"

module BusinessLogic
  # Bare {Command} base class — `param`, `option`, single-shot
  # `#call`, plus the `AlreadyCalled` / `UnknownDependency` error
  # classes. No dependency-injection or form-binding DSL.
  #
  # Defined under the top-level name `BusinessLogic::BaseCommand`
  # so that `BusinessLogic::Command` can inherit from it in
  # `command.rb`; the public alias `BusinessLogic::Command::Base`
  # is wired up there. Apps that want a stricter base — no `.with`,
  # no `.bind_form`, no `.dependency` — should subclass
  # `BusinessLogic::Command::Base` directly.
  #
  # @abstract Subclass and implement {#execute}.
  class BaseCommand
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

    # Initialise the single-shot guard. Forwards to
    # `Dry::Initializer`'s constructor for `param` / `option` /
    # `dependency` wiring, then sets `@__called = false` so reek's
    # InstanceVariableAssumption check is satisfied without a
    # `nil`-vs-`false` quirk in {#call}.
    def initialize(...)
      super
      @__called = false
    end

    # Throw tag used by the auto-yielding helpers ({#yield_result},
    # {#yield_model}) to short-circuit a command without an explicit
    # `yield` at the call site. Caught in {#call} and {#transaction}.
    HALT = :business_logic_halt

    # Run the command. Raises {AlreadyCalled} on the second
    # invocation. Delegates to the subclass's {#execute}, catching any
    # auto-yield ({HALT}) so a failing helper returns its `Failure`.
    #
    # @return [Dry::Monads::Result]
    def call
      raise AlreadyCalled, "#{self.class} already called" if @__called

      @__called = true
      catch(HALT) { execute }
    end

    private

    # Auto-yields a `Result`: returns its value on `Success`, or
    # short-circuits the whole command with the `Failure` (no explicit
    # `yield` needed at the call site). `yield` itself is reserved by Do
    # notation, hence the throw/catch.
    #
    #   organization = yield_result(Organizations::Create.call(attrs:))
    #
    # @param result [Dry::Monads::Result]
    def yield_result(result)
      return result.value! if result.success?

      throw HALT, result
    end

    # Runs an ActiveModel-style write on `record` (in its own context,
    # since `yield` is taken) and returns a `Result` — `Success(record)`
    # on a truthy return, `Failure(record.errors.to_hash)` otherwise.
    # Does NOT auto-yield: use it for a command's terminal step so the
    # result need not be re-wrapped in `Success`, or when you want to
    # branch on the `Result` yourself.
    #
    #   def execute = with_model(invitation) { update(accepted_at: Time.current) }
    #
    # @param record [#errors] an ActiveModel-style record
    # @return [Dry::Monads::Result]
    def with_model(record, &)
      record.instance_exec(&) ? Success(record) : Failure(record.errors.to_hash)
    end

    # Auto-yielding {#with_model}: continues with the record on success,
    # or short-circuits the whole command with its errors. Treats records
    # as first-class in commands — no bang methods, no `save`/`errors`
    # branching, no single-write sub-commands.
    #
    #   user = yield_model(User.new(attrs)) { save }
    #   yield_model(organization.memberships.build(user:)) { save }
    #
    # @param record [#errors] an ActiveModel-style record
    def yield_model(record, &)
      yield_result(with_model(record, &))
    end

    # Wraps `block` in a database transaction that rolls back when a
    # helper auto-yields a `Failure` (or the block returns one). Returns
    # the block's `Result`. Requires ActiveRecord at call time.
    #
    #   transaction do
    #     user = yield_model(User.new(attrs)) { save }
    #     Success(user)
    #   end
    #
    # TODO: a `new_transaction` helper (`requires_new: true` savepoint)
    # for nested transactions that roll back independently of this one
    # on Failure. Postponed; ship it with an app integration test (proven
    # against a real DB in property_management
    # spec/business_logic/new_transaction_spec.rb).
    #
    # @return [Dry::Monads::Result]
    def transaction(&block)
      result = nil
      ActiveRecord::Base.transaction do
        result = catch(HALT) { block.call }
        raise ActiveRecord::Rollback if result.respond_to?(:failure?) && result.failure?
      end
      result
    end

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
