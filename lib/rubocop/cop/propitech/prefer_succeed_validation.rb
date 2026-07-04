# frozen_string_literal: true

module RuboCop
  module Cop
    module Propitech
      # Assert a command / contract / operation *success* with the
      # dedicated `succeed_*` matcher and its `.with_value(...)` payload,
      # never a negated `fail_*`. The negated form passes for any
      # non-failure — including the wrong value — so it silently drops
      # the value contract that `succeed_*.with_value(...)` pins.
      #
      # @example
      #   # bad
      #   expect(result).not_to fail_validation
      #
      #   # good
      #   expect(result).to succeed_validation.with_value(user: { name: "Ada" })
      class PreferSucceedValidation < Base
        MSG = "Assert success with `%<good>s.with_value(...)` instead of `not_to %<bad>s`."

        RESTRICT_ON_SEND = %i[not_to to_not].freeze

        REPLACEMENTS = {
          fail_contract: :succeed_contract,
          fail_validation: :succeed_validation,
          fail_operation: :succeed_operation,
          fail_command: :succeed_command
        }.freeze

        # @!method negated_bare_matcher(node)
        def_node_matcher :negated_bare_matcher, <<~PATTERN
          (send _ {:not_to :to_not} (send nil? $_))
        PATTERN

        def on_send(node)
          bad = negated_bare_matcher(node)
          good = REPLACEMENTS[bad]
          return unless good

          add_offense(node, message: format(MSG, good: good, bad: bad))
        end
      end
    end
  end
end
