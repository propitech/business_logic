# frozen_string_literal: true

module BusinessLogic
  class Command
    # Per-call proxy built by `Command.bind_form(...)`. Wires a
    # {BusinessLogic::Form} into a Command call:
    #
    # - Injects the form as the `:form` dependency on the wrapped
    #   command (the command must declare `dependency :form`).
    # - Reads `form.public_send(method_name)` for each
    #   `command_option => form_method` mapping and passes the
    #   result as a keyword to the call.
    # - On `Failure` whose value is a Hash, calls
    #   `form.assign_errors(failure.to_h)` as a side effect. The
    #   returned `Result` is unchanged — callers still see
    #   `Failure(errors_hash)`.
    #
    # Includes {Chainable} so it composes with `.with` in either
    # order. Marked as a private constant on {Command}.
    class FormBindingProxy
      include Chainable

      def initialize(callable, form:, attribute_mappings:, root_class:)
        @callable = callable
        @form = form
        @attribute_mappings = attribute_mappings
        @root_class = root_class
      end

      def call(*params, **keyword_params)
        invoke(*params, **keyword_params).tap { |result| forward_failure(result) }
      end

      private

      def invoke(*params, **keyword_params)
        @callable.call(*params, **keyword_params, **resolved_attributes, form: @form)
      end

      def resolved_attributes
        @attribute_mappings.transform_values { |method_name| @form.public_send(method_name) }
      end

      def forward_failure(result)
        case result
        in Dry::Monads::Failure(Hash => errors)
          @form.assign_errors(errors)
        else
          nil
        end
      end
    end
    private_constant :FormBindingProxy
  end
end
