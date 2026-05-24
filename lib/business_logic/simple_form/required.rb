# frozen_string_literal: true

module BusinessLogic
  module SimpleForm
    # Teaches `simple_form` to read required-ness from the
    # dry-validation Contract bound to a `BusinessLogic::Form`,
    # without installing fake validators on the Form itself.
    #
    # Apps opt in from a Rails initializer:
    #
    #   # config/initializers/simple_form.rb
    #   SimpleForm::Inputs::Base.prepend(BusinessLogic::SimpleForm::Required)
    #
    # When the form being rendered is a BusinessLogic::Form with a
    # resolvable Contract, the contract's `required(...)` keys drive
    # the required marker (and `aria-required`). For every other
    # builder/object combination — plain models, formtastic, AR
    # models, forms with no contract — control falls through to
    # simple_form's stock `calculate_required` via `super`.
    #
    # `options[:required]` overrides still win: passing
    # `f.input :foo, required: false` (or `true`) is treated as a
    # presentation decision and the contract is not consulted for
    # that input. The contract remains the source of validation
    # truth — overriding the marker does not loosen server-side
    # validation.
    module Required
      def calculate_required
        return super unless contract_backed_form?

        options.fetch(:required) { object.class.attribute_required?(attribute_name) }
      end

      private

      def contract_backed_form?
        object.is_a?(::BusinessLogic::Form) && object.class.contract_class
      end
    end
  end
end
