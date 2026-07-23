# frozen_string_literal: true

module RuboCop
  module Cop
    module Propitech
      # Assert a Paranoia soft-delete through the gem's own `deleted?`
      # predicate — `expect(record).to be_deleted` — rather than poking the
      # `deleted_at` timestamp column. `deleted_at` is the storage detail;
      # `be_deleted` states the behaviour Paranoia guarantees, reads clearly,
      # fails with a readable message, and mirrors how the models are queried.
      #
      # The rewrite preserves polarity: asserting the column is *present*
      # (`to be_present` / `not_to be_nil`) becomes `to be_deleted`, and
      # asserting it is *absent* (`to be_nil` / `not_to be_present`) becomes
      # `not_to be_deleted`.
      #
      # @safety
      #   The autocorrection is not safe: the cop keys off the `deleted_at`
      #   receiver pattern and cannot prove the receiver is a Paranoia model,
      #   so on a non-paranoid record the rewrite would call a `deleted?`
      #   predicate that does not exist. It is marked `SafeAutoCorrect: false`,
      #   so `rubocop -a` only reports the offence; an explicit `rubocop -A`
      #   applies the rewrite.
      #
      # @example
      #   # bad
      #   expect(record.deleted_at).to be_present
      #   expect(record.reload.deleted_at).not_to be_nil
      #   expect(record.deleted_at).to be_nil
      #
      #   # good
      #   expect(record).to be_deleted
      #   expect(record.reload).to be_deleted
      #   expect(record).not_to be_deleted
      class PreferBeDeleted < Base
        extend AutoCorrector

        MSG = "Assert soft-delete with `be_deleted`, not the `deleted_at` column."

        RESTRICT_ON_SEND = %i[to not_to to_not].freeze

        # @!method deleted_at_assertion(node)
        def_node_matcher :deleted_at_assertion, <<~PATTERN
          (send
            (send nil? :expect (send $!nil? :deleted_at))
            ${:to :not_to :to_not}
            (send nil? ${:be_nil :be_present}))
        PATTERN

        def on_send(node)
          deleted_at_assertion(node) do |receiver, verb, matcher|
            deleted = (matcher == :be_present) == (verb == :to)
            new_verb = deleted ? "to" : "not_to"

            add_offense(node) do |corrector|
              corrector.replace(node, "expect(#{receiver.source}).#{new_verb} be_deleted")
            end
          end
        end
      end
    end
  end
end
