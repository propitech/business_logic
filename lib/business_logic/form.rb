# frozen_string_literal: true

require "active_model"

module BusinessLogic
  # Base class for form objects that bridge dry-operation results to
  # Rails form helpers. App-side subclass `ApplicationForm` inherits
  # from this so per-project concerns (i18n hooks, custom error
  # routing) can land in the app without owning the bridge logic.
  #
  # Subclasses declare attributes via `ActiveModel::Attributes` and
  # override `model_name` when the form binds to a non-self param key
  # (e.g. `user_profile`, `address`).
  #
  # @abstract
  class Form
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::Validations

    def self.from_params(params, key: model_name.param_key)
      new(extract_attributes(params, key))
    end

    def self.extract_attributes(params, key)
      raw = params.fetch(key, {})
      permitted = raw.is_a?(ActionController::Parameters) ? raw.permit(attribute_names) : raw
      permitted.to_h.symbolize_keys
    end
    private_class_method :extract_attributes

    # Translate a nested errors hash (dry-validation, AR, or anything
    # shaped like `{attr => [msgs]}` / `{attr => {nested => [msgs]}}`)
    # into ActiveModel::Errors. Unknown top-level keys land on :base;
    # nested keys are joined with dots and added under :base when no
    # matching attribute exists.
    def assign_errors(source)
      flatten(source).each { |attr, messages| add_messages(attr, messages) }
      self
    end

    private

    def add_messages(attr, messages)
      Array(messages).each { |msg| errors.add(attr, msg) }
    end

    def flatten(hash, prefix = nil)
      hash.each_with_object({}) do |(key, value), acc|
        path = prefix ? :"#{prefix}.#{key}" : key.to_sym
        merge_entry(acc, path, value)
      end
    end

    def merge_entry(acc, path, value)
      if value.is_a?(Hash)
        acc.merge!(flatten(value, path))
      else
        target = known_attribute?(path) ? path : :base
        (acc[target] ||= []).concat(Array(value))
      end
    end

    def known_attribute?(name)
      self.class.attribute_names.include?(name.to_s)
    end
  end
end
