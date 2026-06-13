# frozen_string_literal: true

require "dry/monads"

module BusinessLogic
  # Declarative, DB-backed step runner. Subclasses declare an ordered list
  # of steps; each step's success is recorded in `wizard_step_states` via
  # {BusinessLogic::WizardStepState}.
  #
  # Verify-only semantics: a step runs only once every prior step has
  # succeeded (prerequisites are checked, never re-executed), and a
  # succeeded step is skipped — idempotent — unless run via {#reprocess}.
  # The furthest-incomplete step drives resume across requests and sessions.
  #
  # Each step block runs in instance context and must return a dry-monads
  # Result: Success records the step; Failure records the error and leaves
  # the step open.
  #
  #   class ProfileSetup < BusinessLogic::Wizard
  #     step(:basic_info) { |attrs| SaveBasicInfo.call(user: subject, attrs:) }
  #     step(:review)     { Complete.call(user: subject) }
  #   end
  class Wizard
    include Dry::Monads[:result]

    class << self
      def step(name, &block)
        name = name.to_sym
        raise ArgumentError, "step #{name} already declared" if step_blocks.key?(name)

        step_blocks[name] = block
      end

      def step_names
        step_blocks.keys
      end

      # Per-subclass step registry kept in a constant, so neither class
      # instance variables nor class attributes — both flagged by
      # rubocop-thread_safety — are needed. Populated once, at
      # class-definition time, by the `step` macro.
      def step_blocks
        const_defined?(:STEPS, false) ? const_get(:STEPS, false) : const_set(:STEPS, {})
      end

      # Identifies this wizard's rows in the shared table.
      def wizard_key
        name.underscore
      end
    end

    def initialize(subject)
      @subject = subject
      @states = {}
    end

    attr_reader :subject

    # Run +name+ with +input+ once its prerequisites have succeeded; a
    # completed step is skipped. Returns the block's Result,
    # Failure(prerequisites:) when an earlier step is open, or
    # Success(:skipped).
    def process(name, input = nil)
      guarded(name) do
        next Success(:skipped) if step_succeeded?(name)

        state_for(name).record(instance_exec(input, &step_block(name)))
      end
    end

    # Like #process but re-runs the step even if it already succeeded.
    def reprocess(name, input = nil)
      state_for(name).reopen
      process(name, input)
    end

    def step_succeeded?(name)
      state_for(name).succeeded?
    end

    def furthest_incomplete
      names = self.class.step_names
      names.find { |name| !step_succeeded?(name) } || names.last
    end

    def completed?
      self.class.step_names.all? { |name| step_succeeded?(name) }
    end

    private

    def guarded(name)
      name = name.to_sym
      raise ArgumentError, "unknown step #{name}" unless self.class.step_names.include?(name)

      unmet = unmet_prerequisites(name)
      return Failure(prerequisites: unmet) unless unmet.empty?

      yield
    end

    def step_block(name)
      self.class.step_blocks.fetch(name)
    end

    def unmet_prerequisites(name)
      self.class.step_names.take_while { |other| other != name }.reject { |prior| step_succeeded?(prior) }
    end

    def state_for(name)
      @states[name.to_sym] ||=
        WizardStepState.for(subject:, wizard_key: self.class.wizard_key, step_name: name)
    end
  end
end
