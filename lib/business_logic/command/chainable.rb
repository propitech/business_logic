# frozen_string_literal: true

module BusinessLogic
  class Command
    # Shared mixin for {Proxy} and {FormBindingProxy} that lets call
    # chains compose in any order:
    #
    #   Cmd.with(contract: X).bind_form(form: f, attrs: :attributes)
    #   Cmd.bind_form(form: f, attrs: :attributes).with(contract: X)
    #
    # Each proxy carries `@root_class` — the original Command class
    # the chain started from — so `.with`'s dependency validation
    # always checks against the declarations on the real class, not
    # the wrapping proxy.
    module Chainable
      attr_reader :root_class

      def with(**dependency_overrides)
        @root_class.validate_dependency_overrides(dependency_overrides)
        Proxy.new(self, dependency_overrides, root_class: @root_class)
      end

      def bind_form(form:, **attribute_mappings)
        FormBindingProxy.new(self, form: form, attribute_mappings: attribute_mappings, root_class: @root_class)
      end
    end
  end
end
