# frozen_string_literal: true

require "i18n"

module BusinessLogic
  class Command
    # Class-level `rescue_from` for commands, analogous to
    # ActionController's: map an exception raised inside `#execute`
    # to a `Failure` instead of letting it escape. It turns a
    # crafted string-backed-enum value (`ArgumentError` on
    # assignment) or an illegal `aasm` move
    # (`AASM::InvalidTransition`) into a 422:
    #
    #     rescue_from ArgumentError, with: {base: "owner.rates.errors.invalid_selection"}
    #     rescue_from AASM::InvalidTransition, with: :invalid_transition
    #
    # `with:` a Hash maps each key to its translated message —
    # `Failure(key => [I18n.t(value)])`; `with:` a Symbol becomes
    # `Failure(symbol)`.
    #
    # Declarations accumulate in a per-class registry consulted by a
    # single `#call` wrapper — N declarations cost one wrapper, not N
    # prepended modules. The registry is a frozen hash held in a
    # redefined `.rescue_handlers` reader (no mutable class
    # attribute, so it stays thread-safe); a subclass inherits its
    # parent's mappings through ordinary class-method inheritance and
    # may add to them. An unregistered exception propagates
    # unchanged.
    #
    # `BusinessLogic::Command` extends this by default. Extending it
    # also includes {CallWrapper}, which is what actually rescues, so
    # a stricter base ({Command::Base}) opts in with a single
    # `extend BusinessLogic::Command::RescueFrom`.
    module RescueFrom
      # Wraps `#call` — the same method that carries the single-shot
      # guard and the `HALT` catch, both of which stay inside
      # `super`. So an auto-yielded `Failure` returns normally and
      # only a genuinely raised exception reaches a handler.
      module CallWrapper
        def call
          super
        rescue BaseCommand::AlreadyCalled
          # Calling a command twice is a caller bug, not a domain
          # outcome; mapping it to a `Failure` would bury it.
          raise
        rescue StandardError => exception
          failure_for(exception) || raise
        end

        private

        def failure_for(exception)
          _, spec = self.class.rescue_handlers.find { |klass, _| exception.is_a?(klass) }
          build_failure(spec) if spec
        end

        def build_failure(spec)
          case spec
          when Symbol then Failure(spec)
          when Hash then Failure(spec.transform_values { |key| [I18n.t(key)] })
          end
        end
      end

      def self.extended(base)
        super
        base.include(CallWrapper) unless base.include?(CallWrapper)
      end

      # @return [Hash{Class => Symbol, Hash}] exception mappings
      #   declared on this class and its ancestors.
      def rescue_handlers = {}

      # Map `exception_class` (and its subclasses) to the `Failure`
      # payload described by `with:`.
      #
      # @param exception_class [Class]
      # @param with [Symbol, Hash] the `Failure` payload — a Symbol
      #   verbatim, or a Hash whose values are I18n keys.
      def rescue_from(exception_class, with:)
        handlers = rescue_handlers.merge(exception_class => with).freeze
        define_singleton_method(:rescue_handlers) { handlers }
      end
    end
  end
end
