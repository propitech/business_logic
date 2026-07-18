# frozen_string_literal: true

module RuboCop
  module Cop
    module Propitech
      # Never raise `NotImplementedError`. Despite the name it is a
      # `ScriptError`, not a `StandardError`, so a bare `rescue` does not catch
      # it; Ruby reserves it for features the current platform does not
      # implement (a missing `fork(2)`, for example). For an abstract method a
      # subclass must override, or a seam that is not implemented yet, raise
      # `BusinessLogic::AbstractMethodError` — a `NoMethodError`, hence a
      # rescuable `StandardError` — instead.
      #
      # @safety
      #   The autocorrection is not safe: it changes the raised exception's
      #   ancestry from `ScriptError` to `StandardError`, so a surrounding
      #   `rescue` (bare, `StandardError`, `ScriptError`, or `Exception`) may
      #   start or stop catching it. It is marked `SafeAutoCorrect: false`, so
      #   `rubocop -a` only reports the offence; an explicit `rubocop -A`
      #   applies the rewrite.
      #
      # @example
      #   # bad
      #   def call = raise NotImplementedError
      #   def call = raise NotImplementedError, "subclass must implement #call"
      #   def call = raise ::NotImplementedError.new("…")
      #
      #   # good
      #   def call = raise BusinessLogic::AbstractMethodError
      #   def call = raise BusinessLogic::AbstractMethodError, "subclass must implement #call"
      class NoNotImplementedError < Base
        extend AutoCorrector

        MSG = "Raise `BusinessLogic::AbstractMethodError` (a rescuable " \
              "`NoMethodError`), not `NotImplementedError` (a `ScriptError`)."

        REPLACEMENT = "BusinessLogic::AbstractMethodError"

        RESTRICT_ON_SEND = %i[raise fail].freeze

        # @!method raised_not_implemented(node)
        def_node_matcher :raised_not_implemented, <<~PATTERN
          (send nil? {:raise :fail}
            {
              $(const {nil? cbase} :NotImplementedError)
              (send $(const {nil? cbase} :NotImplementedError) :new ...)
            }
            ...)
        PATTERN

        def on_send(node)
          const = raised_not_implemented(node)
          return unless const

          add_offense(const) do |corrector|
            corrector.replace(const, REPLACEMENT)
          end
        end
      end
    end
  end
end
