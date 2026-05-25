# frozen_string_literal: true

module BusinessLogic
  class Command
    # Opt-in class-level mixin that adds the dependency-injection
    # DSL to a {Command} subclass:
    #
    # - `dependency :name, default: -> { ... }` — declare a keyword
    #   collaborator (equivalent to `option name` plus registration
    #   in the per-class dependency set).
    # - `.with(**overrides)` — return a {Proxy} that injects
    #   `overrides` into the constructor at call time. Raises
    #   {UnknownDependency} if any override key was not declared via
    #   `dependency`.
    #
    # `ApplicationCommand` extends this by default in the install
    # template. Apps that want a stricter base can subclass
    # {Command} without it and opt in per-command.
    #
    # @example
    #   class ApplicationCommand < BusinessLogic::Command
    #     extend BusinessLogic::Command::DependencyInjection
    #   end
    module DependencyInjection
      def self.extended(base)
        super
        # Guard against double-extension. The hook fires every
        # time `extend DependencyInjection` runs (even on a class
        # that inherits from one already extended), and a blind
        # assignment here would wipe the dependency set the
        # subclass dup'd in `inherited`.
        return if base.instance_variable_defined?(:@dependencies)

        base.instance_variable_set(:@dependencies, Set.new)
      end

      # @return [Set<Symbol>] dependency names declared on this class.
      attr_reader :dependencies

      # Dup the parent's dependency set onto the subclass so that
      # additions stay local. Chained via `super` so it cooperates
      # with any other `inherited` hook in the ancestor chain.
      def inherited(subclass)
        super
        subclass.instance_variable_set(:@dependencies, dependencies.dup)
      end

      # Declare an injectable collaborator. Sugar for
      # `option name, **opts, &block` plus registration in the
      # class-level dependency set, which is the only set of names
      # `.with(...)` may override.
      def dependency(name, **, &)
        dependencies << name.to_sym
        option(name, **, &)
      end

      # Build a per-call proxy that injects `dependency_overrides`
      # into the constructor of every command built through it.
      # Raises {UnknownDependency} if any override key is not a
      # declared dependency.
      #
      # @return [Proxy]
      def with(**dependency_overrides)
        validate_dependency_overrides(dependency_overrides)
        Proxy.new(self, dependency_overrides, root_class: self)
      end

      # Public so chained proxies can re-validate further overrides
      # against the original Command class. Not part of the docs-
      # facing API — callers should reach for `.with` instead.
      def validate_dependency_overrides(dependency_overrides)
        declared = dependencies.to_a
        unknown = dependency_overrides.keys - declared
        return if unknown.empty?

        raise Command::UnknownDependency,
          "#{name || self}.with: #{unknown.inspect} not in declared dependencies #{declared.inspect}"
      end
    end
  end
end
