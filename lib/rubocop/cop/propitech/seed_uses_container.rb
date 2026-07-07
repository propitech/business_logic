# frozen_string_literal: true

module RuboCop
  module Cop
    module Propitech
      # Keeps a seed to the two sanctioned moves: build rows with FactoryBot, and
      # reach for a row another seed already built through the shared container.
      # A `BusinessLogic::Seed` runs against a container the ordered seeds hand
      # records forward through (`container.set(:demo_school, ...)` upstream,
      # `container.get(:demo_school)` downstream). Any direct ActiveRecord
      # persistence or lookup verb -- on a model class or on an instance -- breaks
      # that: it couples seeds by hard-coded identifiers, re-runs write logic the
      # factory already owns, or mutates a row that should have been built in its
      # final state.
      #
      # Flagged on any receiver except `FactoryBot` / `FactoryGirl`:
      #
      # * lookup -- `find`, `find_by`, `find_by!`, `find_sole_by`, ... (steer to
      #   `container.get`);
      # * creation -- anything with `create` or `initialize` in the name
      #   (`find_or_create_by`, `find_or_initialize_by`, `create_with`, ...),
      #   steered to `FactoryBot.create`;
      # * mutation -- anything with `save`, `update`, `destroy`, or `delete` in
      #   the name (`save!`, `update!`, `update_all`, `destroy_all`, `delete_all`,
      #   ...), steered to a FactoryBot trait that builds the final state.
      #
      # Exact `create` / `create!` are left to the `SeedUsesFactory` cop so a
      # single call is not reported twice.
      #
      # Iteration is allowed: `find_each` and the block form `find { ... }` walk a
      # collection rather than fetch one known record, so they pass.
      #
      # This cop is meant to run only over the seed files (scope it with
      # +Include+, as the shipped default does).
      #
      # @example
      #   # bad
      #   school = School.find_by(slug: "movely-demo")
      #   Membership.find_or_create_by!(user:, school:, role: "admin")
      #   invoice.update!(due_at: 3.days.ago)
      #
      #   # good
      #   school = container.get(:demo_school)
      #   FactoryBot.create(:membership, :admin, user:, school:)
      #   FactoryBot.create(:invoice, :overdue, enrolment:)
      class SeedUsesContainer < Base
        MSG_LOOKUP = "Do not look up records with `%<method>s` in a seed. Fetch a record " \
                     "another seed owns through the shared container (`container.get(:key)`, " \
                     "set upstream with `container.set`)."
        MSG_CREATE = "Do not build a seed row with `%<method>s` -- creation goes through " \
                     "FactoryBot. Use `FactoryBot.create(:model, :trait)`."
        MSG_MUTATE = "Do not mutate a persisted record with `%<method>s` in a seed. Build the " \
                     "row in its final state with a FactoryBot factory and trait."

        # @!method non_factory_call(node)
        # Captures the method name of a `send` whose receiver exists and is not
        # `FactoryBot` / `FactoryGirl`; nil otherwise.
        def_node_matcher :non_factory_call, <<~PATTERN
          (send [!nil? !(const _ {:FactoryBot :FactoryGirl})] $_ ...)
        PATTERN

        def on_send(node)
          message = offense_message(node)
          return unless message

          add_offense(node.loc.selector, message: format(message, method: node.method_name))
        end

        private

        def offense_message(node)
          method = non_factory_call(node)
          return unless method
          return if method == :find && node.block_literal?

          Verbs.message(method)
        end

        # Maps a method name to the message for its verb family, or nil when it is
        # not a forbidden persistence/lookup call. Pure classification, so it lives
        # in a module_function module -- no instance state.
        module Verbs
          module_function

          # Exact `create` / `create!` belong to the `SeedUsesFactory` cop;
          # `find_each` walks a collection. Neither is reported here.
          EXEMPT = %i[create create! find_each].freeze

          # First matching pattern wins; a method matching none is left alone.
          # The verb must be a whole token (bounded by start/end, `_`, or `!`) so
          # a scope or reader that merely contains it -- `with_deleted`,
          # `created_at`, `deleted?` -- is not mistaken for the verb. `create` and
          # `initialize` stay unanchored on the left to catch `find_or_create_by`
          # and `find_or_initialize_by`.
          BY_PATTERN = [
            [/(\A|_)(create|initialize)(_|!|\z)/, MSG_CREATE],
            [/(\A|_)(save|update|destroy|delete)(_|!|\z)/, MSG_MUTATE],
            [/\Afind(_|!|\?|\z)/, MSG_LOOKUP]
          ].freeze

          def message(method)
            return if EXEMPT.include?(method)

            name = method.to_s
            BY_PATTERN.find { |pattern, _| name.match?(pattern) }&.last
          end
        end
      end
    end
  end
end
