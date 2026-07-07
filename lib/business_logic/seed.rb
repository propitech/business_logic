# frozen_string_literal: true

module BusinessLogic
  # Base class for a dependency-ordered, idempotent seed registry shared across
  # Propitech apps. Each seed is a subclass implementing #call; the registry
  # discovers every subclass, orders them by their declared dependencies, and
  # runs each once against a shared container. Progress goes through #say to the
  # container's IO, so a test can capture it without touching $stdout.
  #
  # Pure Ruby by design: no Rails and no ActiveSupport. A host app points the
  # loader at its seed directory and supplies any app-specific constants by
  # subclassing (see .default_seeds_dir).
  #
  #   class Seed < BusinessLogic::Seed
  #     def self.default_seeds_dir = Rails.root.join("db/seeds")
  #   end
  #
  #   module Seeds
  #     class Users < Seed
  #       def call = container.set(:users, create_users)
  #     end
  #
  #     class Company < Seed
  #       depends_on :users
  #       def call = ...
  #     end
  #   end
  #
  #   Seed.run_all
  class Seed
    # Raised when the seeds' declared dependencies form a cycle.
    class CircularDependencyError < StandardError; end

    # A small key/value bag the registry shares across one seed run, so a seed
    # can hand the records it builds to later seeds instead of re-querying. It
    # also owns the IO that #say writes to, so a test can pass a StringIO to
    # stay quiet.
    class Container
      def initialize(output: $stdout)
        @store = {}
        @output = output
      end

      attr_reader :output

      def set(key, value) = @store[key] = value
      def get(key) = @store.fetch(key)
    end

    # Topologically orders seed classes so each one's declared dependencies come
    # before it, raising CircularDependencyError on a cycle. A seed declares its
    # dependencies by underscored name (depends_on :users); each name resolves to
    # a sibling constant in the same namespace, so declaration order across files
    # never matters. Resolution is plain Ruby — a small stand-in for the subset
    # of ActiveSupport's module_parent/camelize this needs.
    class Ordering
      def initialize(seed_classes)
        @seed_classes = seed_classes
      end

      def call
        @seed_classes.each_with_object([]) { |seed_class, acc| visit(seed_class, acc, []) }
      end

      private

      def visit(seed_class, acc, stack)
        return if acc.include?(seed_class)
        raise CircularDependencyError, Naming.cycle_message(stack, seed_class) if stack.include?(seed_class)

        Naming.dependencies_of(seed_class).each { |dependency| visit(dependency, acc, stack + [seed_class]) }
        acc << seed_class
      end

      # Pure name/constant helpers, kept as module functions so they read as the
      # stateless utilities they are. Together they stand in for the subset of
      # ActiveSupport's module_parent/camelize the dependency resolution needs.
      module Naming
        module_function

        # A seed's dependencies as constants, resolved from its underscored keys
        # against its own namespace (depends_on :users => sibling Users).
        def dependencies_of(seed_class)
          seed_class.dependency_keys.map { |key| enclosing_module(seed_class).const_get(camelize(key)) }
        end

        # The module enclosing the seed, or Object for a top-level seed.
        def enclosing_module(seed_class)
          segments = seed_class.name.to_s.split("::")
          segments.size > 1 ? Object.const_get(segments[0..-2].join("::")) : Object
        end

        # :cycle_one => "CycleOne".
        def camelize(key)
          key.to_s.split("_").map(&:capitalize).join
        end

        def cycle_message(stack, seed_class)
          "Seed dependency cycle: #{(stack + [seed_class]).map(&:name).join(' -> ')}"
        end
      end
    end

    class << self
      # Declare the seeds that must run first, by their underscored name (e.g.
      # depends_on :users). Resolved lazily against this seed's namespace at
      # ordering time, so a declaration never depends on file load order.
      def depends_on(*keys)
        define_singleton_method(:dependency_keys) { keys }
      end

      def dependency_keys = []

      # Load every seed definition under dir, then run each once in dependency
      # order. dir defaults to .default_seeds_dir; pass dir: nil when the seed
      # files are already loaded.
      def run_all(container = Container.new, dir: default_seeds_dir)
        load_definitions(dir) if dir
        run(concrete_seeds, container)
      end

      # Run the given seed classes once each, dependencies first.
      def run(seed_classes, container = Container.new)
        ordered(seed_classes).each { |seed_class| seed_class.new(container).call }
        container
      end

      # The given seeds with each one's dependencies placed before it.
      def ordered(seed_classes) = Ordering.new(seed_classes).call

      # A host app overrides this to point at its seed directory (e.g.
      # Rails.root.join("db/seeds")). Nil keeps the gem framework-agnostic.
      def default_seeds_dir = nil

      private

      # Every named seed subclass at any depth, deterministically by name.
      # Walks Ruby-core Class#subclasses recursively, so it survives the
      # two-level chain (Seeds::Foo < AppSeed < BusinessLogic::Seed) without
      # ActiveSupport's descendants.
      def registry
        descendants_of(self).select(&:name).sort_by(&:name)
      end

      def descendants_of(klass)
        klass.subclasses.flat_map { |subclass| [subclass, *descendants_of(subclass)] }
      end

      # The registered seeds that actually implement #call — the concrete ones.
      # Excludes abstract bases (a host-app alias, this class) that only inherit
      # the NotImplementedError #call, so run_all runs real seeds only.
      def concrete_seeds
        registry.reject { |seed_class| seed_class.instance_method(:call).owner == Seed }
      end

      def load_definitions(dir)
        Dir.glob(File.join(dir.to_s, "*.rb")).each { |path| require path }
      end
    end

    def initialize(container)
      @container = container
    end

    attr_reader :container

    def call = raise(NotImplementedError, "#{self.class.name} must implement #call")

    def say(message) = container.output.puts(message)
  end
end
