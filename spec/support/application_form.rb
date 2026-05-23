# frozen_string_literal: true

require "active_model"

# Base class for form objects that bridge dry-operation results to
# Rails form helpers. Subclasses declare attributes via
# `ActiveModel::Attributes` and override `model_name` when the form
# binds to a non-self param key.
#
# @abstract
class ApplicationForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  def self.from_params(params, key: model_name.param_key)
    raw = params.fetch(key, {})
    permitted = raw.respond_to?(:permit) ? raw.permit(attribute_names) : raw
    new(permitted.to_h.symbolize_keys)
  end

  def assign_errors(source)
    flatten(source).each do |attr, messages|
      Array(messages).each { |msg| errors.add(attr, msg) }
    end
    self
  end

  private

  def flatten(hash, prefix = nil)
    hash.each_with_object({}) do |(key, value), acc|
      path = prefix ? :"#{prefix}.#{key}" : key.to_sym
      if value.is_a?(Hash)
        acc.merge!(flatten(value, path))
      else
        target = known_attribute?(path) ? path : :base
        (acc[target] ||= []).concat(Array(value))
      end
    end
  end

  def known_attribute?(name)
    self.class.attribute_names.include?(name.to_s)
  end
end
