# frozen_string_literal: true

module RuboCop
  module Cop
    module Propitech
      # Assert a command / contract / operation *failure* with the
      # dedicated `fail_*` matcher and its `.with_error(...)` payload,
      # never a negated `succeed_*`. The negated form passes for any
      # non-success — including the wrong error — so it silently drops
      # the error contract that `fail_*.with_error(...)` pins.
      #
      # @example
      #   # bad
      #   expect(result).not_to succeed_validation
      #
      #   # good
      #   expect(result).to fail_validation.with_error(hash_including(:email))
      class PreferFailValidation < Base
        MSG = "Assert failure with `%<good>s.with_error(...)` instead of `not_to %<bad>s`."

        RESTRICT_ON_SEND = %i[not_to to_not].freeze

        REPLACEMENTS = {
          succeed_contract: :fail_contract,
          succeed_validation: :fail_validation,
          succeed_operation: :fail_operation,
          succeed_command: :fail_command
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
