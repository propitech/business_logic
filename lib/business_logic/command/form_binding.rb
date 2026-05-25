# frozen_string_literal: true

module BusinessLogic
  class Command
    # Opt-in class-level mixin that adds `.bind_form(form:, **mappings)`
    # to a {Command} subclass. The wrapped command must:
    #
    # - declare `dependency :form` (so the form may be injected via
    #   the same path as `.with`); and
    # - extend {DependencyInjection} (so the chain validates
    #   override keys correctly).
    #
    # `ApplicationCommand` extends this by default in the install
    # template alongside {DependencyInjection}.
    #
    # @example
    #   class Commands::UpdateUser < ApplicationCommand
    #     dependency :form
    #     option     :user
    #     option     :user_attributes
    #
    #     def execute
    #       attrs = yield validate(user_attributes)
    #       save(attrs)
    #     end
    #   end
    #
    #   Commands::UpdateUser
    #     .bind_form(form: my_form, user_attributes: :attributes)
    #     .call(user: @user)
    module FormBinding
      def bind_form(form:, **attribute_mappings)
        FormBindingProxy.new(self, form: form, attribute_mappings: attribute_mappings, root_class: self)
      end
    end
  end
end
