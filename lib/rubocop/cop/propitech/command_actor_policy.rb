# frozen_string_literal: true

module RuboCop
  module Cop
    module Propitech
      # Requires every command to declare who may run it. A class declared
      # with +< ApplicationCommand+ must call one of the configured policy
      # macros directly in its body, so a command never ships without an actor
      # decision.
      #
      # The macros are cop configuration, never hard-coded, because the gem
      # serves more than one app. List them under +PolicyMacros+. An entry is a
      # method name (+runs_as_system+), or a method name followed by a symbol
      # when the macro is only a policy for that first argument (+option :actor+
      # matches +option :actor+ and not +option :user+). With an empty list the
      # cop reports nothing.
      #
      # This cop is meant to run only over the commands directory (scope it
      # with +Include+, as the shipped default does).
      #
      # The check is static. It reads the class body only, so a declaration
      # inherited from a parent class or a concern is not seen and the command
      # is flagged. A command that inherits through an intermediate base class,
      # or is built with +Class.new(ApplicationCommand)+, is never checked.
      #
      # @example PolicyMacros: ['option :actor', 'runs_as_system']
      #   # bad
      #   class Commands::Spaces::Create < ApplicationCommand
      #     option :user
      #   end
      #
      #   # good
      #   class Commands::Spaces::Create < ApplicationCommand
      #     option :actor
      #   end
      #
      #   # good
      #   class Commands::Spaces::Sweep < ApplicationCommand
      #     runs_as_system
      #   end
      class CommandActorPolicy < Base
        MSG = "Declare who may run `%<name>s` with one of: %<macros>s."

        # @!method application_command?(node)
        def_node_matcher :application_command?, <<~PATTERN
          (class _ (const {nil? cbase} :ApplicationCommand) ...)
        PATTERN

        # @!method bare_macro?(node, name)
        def_node_matcher :bare_macro?, "(send nil? %1 ...)"

        # @!method macro_with_symbol?(node, name, symbol)
        def_node_matcher :macro_with_symbol?, "(send nil? %1 (sym %2) ...)"

        def on_class(node)
          return unless application_command?(node)
          return if policies.empty? || declares_policy?(node)

          identifier = node.identifier
          add_offense(identifier, message: format(MSG, name: identifier.source, macros: macro_list))
        end

        private

        def policies
          @policies ||= Array(cop_config["PolicyMacros"]).map do |entry|
            name, symbol = entry.to_s.split
            [name.to_sym, symbol&.delete_prefix(":")&.to_sym]
          end
        end

        def macro_list
          policies.map { |name, symbol| "`#{[name, symbol && ":#{symbol}"].compact.join(' ')}`" }.join(", ")
        end

        def declares_policy?(node)
          body = node.body
          statements = body&.begin_type? ? body.children : [body]
          statements.any? { |statement| policy?(statement) }
        end

        def policy?(statement)
          policies.any? do |name, symbol|
            symbol ? macro_with_symbol?(statement, name, symbol) : bare_macro?(statement, name)
          end
        end
      end
    end
  end
end
