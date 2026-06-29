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

    # Bind a dry-validation Contract explicitly, bypassing the
    # naming convention used by `.contract_class`. Subclasses that
    # cannot follow the `Forms::Foo -> Contracts::Foo` mirroring
    # (renamed namespaces, shared contract across forms, etc.) reach
    # for this. Implemented by redefining `.contract_class` on the
    # caller's singleton — no mutable class attributes, no thread
    # safety concerns at request time.
    def self.validates_with_contract(contract_class)
      singleton_class.define_method(:contract_class) { contract_class }
    end

    # Resolve the dry-validation Contract bound to this form. Returns
    # the explicit binding when `validates_with_contract` was called
    # (the override sits on the caller's singleton class), otherwise
    # applies the Forms:: <-> Contracts:: naming convention and
    # strips the trailing "Form" suffix from the class basename.
    # Returns nil when no matching constant exists or when the form's
    # namespace does not contain a `Forms` segment.
    def self.contract_class
      resolve_contract_class_by_convention
    end

    def self.resolve_contract_class_by_convention
      contract_constant_name_for(name)&.safe_constantize
    end
    private_class_method :resolve_contract_class_by_convention

    FORMS_NAMESPACE_BOUNDARY = /(?<=\A|::)Forms::/
    private_constant :FORMS_NAMESPACE_BOUNDARY

    def self.contract_constant_name_for(form_name)
      return unless form_name&.match?(/(?:\A|::)Forms::/)

      form_name.gsub(FORMS_NAMESPACE_BOUNDARY, "Contracts::").sub(/Form\z/, "Contract")
    end
    private_class_method :contract_constant_name_for

    # Set of attribute names (strings) the bound Contract declares
    # as top-level required keys. Returns an empty Set when no
    # Contract resolves, when the Contract cannot be instantiated
    # via `.new` (constructor takes arguments), or when calling the
    # Contract raises. Probes by calling `contract.new.call({})`
    # and reading `errors.to_h.keys` — only `required(...)` keys
    # produce "is missing" errors against an empty hash, so
    # `optional(...)` keys are excluded by construction.
    #
    # Result is memoised per form class in a thread-safe
    # Concurrent::Map keyed by class. Cache invalidation on contract
    # reload (e.g. Rails autoload in dev) is not handled — call
    # `BusinessLogic::Form::REQUIRED_ATTRIBUTES_CACHE.clear` if you
    # need to reset between hot reloads.
    REQUIRED_ATTRIBUTES_CACHE = Concurrent::Map.new

    def self.required_attributes
      REQUIRED_ATTRIBUTES_CACHE.compute_if_absent(self) do
        contract_class&.then { |contract| probe_required_attributes(contract) }&.freeze ||
          Set.new.freeze
      end
    end

    def self.probe_required_attributes(contract)
      contract.new.call({}).errors.to_h.keys.to_set(&:to_s)
    rescue ArgumentError, NoMethodError
      Set.new
    end
    private_class_method :probe_required_attributes

    # True when the named attribute is required by the bound
    # Contract, OR — when no Contract resolves — when the form
    # declares a presence validator on that attribute. The fallback
    # preserves the default ActiveModel/simple_form behaviour for
    # forms that opt out of contract-driven inference.
    # Accepts symbols or strings.
    def self.attribute_required?(attribute_name)
      required_attributes.include?(attribute_name.to_s) ||
        presence_validated?(attribute_name)
    end

    def self.presence_validated?(attribute_name)
      validators_on(attribute_name).any?(ActiveModel::Validations::PresenceValidator)
    end
    private_class_method :presence_validated?

    # Instance-level shim for form builders that ask the object
    # directly (e.g. formtastic, custom builders). simple_form takes
    # a different path — see `BusinessLogic::SimpleForm::Required`
    # for the prepend-based integration apps opt into.
    def required?(attribute_name)
      self.class.attribute_required?(attribute_name)
    end

    def self.from_params(params, key: model_name.param_key)
      new(extract_attributes(params, key))
    end

    # A form is a UI <-> business-logic bridge, never a security gate: the
    # Contract is the authoritative input filter and the Model still raises
    # ForbiddenAttributesError on a direct mass-assign. So convert params with
    # `to_unsafe_h` rather than a strong-params `permit` — a scalar
    # `permit(attribute_names)` would silently drop array (`ids: []`) and nested
    # (`*_attributes`) shapes, forcing every such form to re-declare a permit
    # list. Unknown keys are ignored at assignment (see #attribute_writer_missing),
    # so a form keeps only the attributes it declares while those shapes survive.
    def self.extract_attributes(params, key)
      raw = params.fetch(key, {})
      raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : raw
    end
    private_class_method :extract_attributes

    # Ignore params the form does not declare, rather than raising
    # UnknownAttributeError (ActiveModel's default). The form is not a security
    # gate — the Contract filters and validates input downstream — so stray keys
    # carried through by `to_unsafe_h` are simply dropped here.
    def attribute_writer_missing(_name, _value) = nil

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
