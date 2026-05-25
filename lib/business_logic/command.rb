# frozen_string_literal: true

require "dry-initializer"
require "dry/monads"
require "dry/monads/do"

module BusinessLogic
  # Base class for OOP-style domain commands. Sibling to
  # `Dry::Operation`: same public instance interface (`#call`
  # returning a `Dry::Monads::Result`) so both can call each other
  # as steps, but a different internal shape.
  #
  # A `Command` is a stateful service object — collaborators and
  # input data are captured at `#initialize` time via
  # `Dry::Initializer`. Three DSLs are exposed:
  #
  # - `param :name` — positional input data.
  # - `option :name` — keyword input data.
  # - `dependency :name, default: -> { ... }` — keyword injected
  #   collaborator. Equivalent to `option` plus registration in the
  #   class-level dependency set, which is the only set of names
  #   `.with(...)` may override.
  #
  # `#call` takes no arguments and is single-shot: a second
  # invocation raises {AlreadyCalled}. Subclasses override
  # `#execute` (not `#call`); the base wraps the override with the
  # single-shot guard.
  #
  # @abstract Subclass and implement {#execute}.
  #
  # @example
  #   class Commands::CreateUser < ApplicationCommand
  #     option     :user
  #     option     :form
  #     dependency :contract, default: -> { Contracts::CreateUserContract.new }
  #
  #     def execute
  #       attrs = yield validate
  #       Success(yield persist(attrs))
  #     end
  #
  #     private
  #
  #     def validate
  #       result = contract.call(form.attributes.symbolize_keys)
  #       return Success(result.to_h) if result.success?
  #
  #       form.assign_errors(result.errors.to_h)
  #       Failure(form)
  #     end
  #
  #     def persist(attrs)
  #       user.assign_attributes(attrs)
  #       return Success(user) if user.save
  #
  #       form.assign_errors(user.errors.to_hash)
  #       Failure(form)
  #     end
  #   end
  #
  #   Commands::CreateUser.call(user:, form:)
  #   Commands::CreateUser.with(contract: Other.new).call(user:, form:)
  class Command
    extend Dry::Initializer
    include Dry::Monads[:result, :do]

    # Raised when {#call} is invoked more than once on the same
    # instance. Commands are single-shot by design — construct a
    # new instance to re-run.
    class AlreadyCalled < StandardError; end

    # Raised by `.with(...)` when an override key is not a declared
    # {dependency}.
    class UnknownDependency < ArgumentError; end

    # Set of dependency names declared on this class. Subclasses
    # inherit a duplicate via `inherited` — additions stay local.
    @dependencies = Set.new

    def self.inherited(subclass)
      super
      subclass.instance_variable_set(:@dependencies, dependencies.dup)
    end

    class << self
      attr_reader :dependencies
    end

    # Declare an injectable collaborator. Equivalent to
    # `option name, **opts, &block` plus registration in the
    # class-level dependency set, which is the only set of names
    # `.with(...)` may override.
    def self.dependency(name, **, &)
      dependencies << name.to_sym
      option(name, **, &)
    end

    # Sugar for `new(*params, **keyword_params).call`. Use when no
    # per-call dependency overrides are needed.
    def self.call(*params, **keyword_params)
      new(*params, **keyword_params).call
    end

    # Build a per-call proxy that injects `dependency_overrides`
    # into the constructor of every command built through it.
    # Raises {UnknownDependency} if any override key is not a
    # declared {dependency}.
    #
    # @return [Proxy]
    def self.with(**dependency_overrides)
      validate_dependency_overrides(dependency_overrides)
      Proxy.new(self, dependency_overrides)
    end

    def self.validate_dependency_overrides(dependency_overrides)
      declared = dependencies.to_a
      unknown = dependency_overrides.keys - declared
      return if unknown.empty?

      raise UnknownDependency,
        "#{name || self}.with: #{unknown.inspect} not in declared dependencies #{declared.inspect}"
    end
    private_class_method :validate_dependency_overrides

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

require_relative "command/proxy"
