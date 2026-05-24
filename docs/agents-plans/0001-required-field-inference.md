# 0001 — Required-field inference from dry-validation contracts

**Status:** landed
**Owner:** @hery
**Created:** 2026-05-23

## Goal

Make `simple_form_for @form` automatically render the "required" marker
(and `aria-required="true"`) for any attribute the bound contract
declares as `required(...)` — without the developer repeating that
information on the Form class.

Single source of truth: the dry-validation `Contracts::*` class.
`Forms::*` keep their job of carrying submitted attributes and errors;
"is this field required?" becomes a derived property, not a declared
one.

## Why convention-driven

This gem already leans on convention: `Forms::CreateUser` →
`Operations::CreateUser` → `Contracts::CreateUser` are linked by name
alone. Required-field inference extends that idea.

A convention-driven shape buys us three things:

1. **Less duplication.** The Contract is the only place that knows
   what is required. Forms stop drifting from it.
2. **Predictable navigation for humans _and_ AI agents.** Given any
   Form, both can locate the Contract by name. No registry to grep
   for, no DSL to memorise.
3. **Cheap overrides.** When convention does not fit, one line
   (`validates_with_contract Contracts::Foo`) opts out without
   changing the call site of `simple_form_for`.

The README's "Usage" section will gain a short **Convention-driven
architecture** call-out documenting the Form ↔ Contract ↔ Operation
naming rule and the override hatch.

## Deliverables

### Gem code

1. `BusinessLogic::Form` gains:
   - `.validates_with_contract(contract_class)` — explicit binding,
     stored in `@contract_class`.
   - `.contract_class` — returns the explicit binding if set,
     otherwise resolves via convention (see §Convention).
     Memoised per class.
   - `.required_attributes` — `Set` of attribute names (strings) the
     contract declares as top-level `required(...)`. Empty set when
     no contract resolvable. Memoised per class.
   - `.attribute_required?(attribute_name)` — `true` when the name
     is in `required_attributes`. Falls back to presence-validator
     introspection when no contract resolvable (preserves existing
     ActiveModel behaviour).
   - `#required?(attribute_name)` — delegates to the class method.
2. Resolution of the contract from the form schema runs once per
   class (memoised). No I/O at request time.

### Convention

Given a form class `name`:

```text
Forms::Users::Profile::BasicInfoForm
        │                  │
        │                  └── strip trailing "Form"  → "BasicInfo"
        └── replace top-level "Forms::" with "Contracts::"
                                  ↓
Contracts::Users::Profile::BasicInfoContract
```

Implementation: `name.sub(/\AForms::/, "Contracts::").sub(/Form\z/, "Contract").safe_constantize`.

A form not under the `Forms::` namespace, or with a name that does
not match the pattern, returns `nil` from convention resolution and
silently falls back to ActiveModel behaviour. Convention failure is
not an error.

### Contract introspection

dry-schema's `KeyMap` does **not** distinguish required from optional
keys (verified against `dry-schema 1.14.1`: `Dry::Schema::Key` has no
`required?` predicate, and `optional(:foo)` registers a key the same
way `required(:foo)` does).

Reliable inference path: call the contract against an empty hash and
inspect the resulting errors.

```ruby
contract.new.call({}).errors.to_h.keys
```

Only `required(...)` keys produce `"is missing"` errors against `{}`;
`optional(...)` keys are skipped. Nested `required(:address).hash {
... }` reports `:address` at the top level and does not drill into
`address.line1` — matches the scope decided in §Out of scope.

Contracts that take constructor arguments (`option :foo` etc.) cannot
be instantiated via `.new`. The introspector rescues `ArgumentError`
and returns an empty set in that case, falling back to ActiveModel
behaviour.

### Tests (TDD — red before green)

All under `spec/business_logic/form_spec.rb` plus a new
`spec/business_logic/form_required_spec.rb`:

1. `.contract_class` resolves a sibling Contract via the convention.
2. `.contract_class` returns `nil` when no matching constant exists.
3. `.validates_with_contract` overrides the convention.
4. `.required_attributes` reflects the contract's top-level
   `required(...)` keys; ignores `optional(...)` keys.
5. `.required_attributes` is empty when no contract resolvable.
6. `.attribute_required?` returns `true` for required keys and
   `false` for optional ones.
7. `#required?(:foo)` returns the same as `.attribute_required?(:foo)`.
8. Fallback: a form with no contract but with a presence validator
   on an attribute still returns `true` from
   `.attribute_required?` — backwards compatibility.
9. Memoisation: introspecting the schema twice does not call into
   dry-validation twice (assert via a spy or by stubbing
   `schema.key_map` and counting calls).
10. simple_form integration (redesigned — see §"simple_form
    actually inspects validators_on, not attribute_required?" below):
    asserts the new `BusinessLogic::SimpleForm::Required` module
    delegates to `attribute_required?` for contract-backed forms,
    honours `options[:required]` overrides, and falls through to
    `super` for any other object. Spec uses a hand-rolled
    `StubInput`, no simple_form runtime dependency.

Spec uses anonymous form + contract classes defined inline (mirrors
existing `form_spec.rb` style), no Rails app required.

### simple_form actually inspects `validators_on`, not `attribute_required?`

Mid-implementation check against `simple_form 5.4.1` corrected the
plan's original premise. simple_form's `Helpers::Required` /
`Helpers::Validators` modules compute "required" via:

```ruby
def calculate_required
  if !options[:required].nil?
    options[:required]
  elsif has_validators?              # true for any ActiveModel class
    required_by_validators?          # any presence-kind validator?
  else
    required_by_default?             # config fallback
  end
end
```

It never calls `required?` or `attribute_required?` on the object.
The instance/class predicates introduced in steps 3–5 stay because
they remain useful for formtastic, custom builders, and direct
introspection — but the simple_form integration requires that we
install a presence-kind validator on the Form for each contract-
required attribute.

**Mechanism (step 7, redesigned post-review):**

The first cut of step 7 installed a `ContractPresenceValidator`
no-op presence validator on the Form for each required attribute
so that simple_form's existing `required_by_validators?` filter
would pick it up. Review surfaced two issues with that path:

1. The integration coupled Form to simple_form even for apps that
   use formtastic or `form_with` — every Form mutated its
   `validators_on` list whether or not anything cared.
2. Installing a `PresenceValidator` subclass that no-ops
   `validate_each` is a maintenance booby-trap: the class signals
   "presence check" but the only reason it exists is to lie to
   simple_form. `Form#valid?` would also surprise anyone who
   reasoned from the class hierarchy.

Replaced with an **opt-in module** that hooks simple_form's actual
decision point:

```ruby
module BusinessLogic
  module SimpleForm
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
```

Apps opt in from a Rails initializer:

```ruby
# config/initializers/simple_form.rb
require "business_logic/simple_form/required"

SimpleForm::Inputs::Base.prepend(BusinessLogic::SimpleForm::Required)
```

Properties of the redesign:

- Form stays a pure `ActiveModel` object. `validators_on` is not
  mutated, `Form#valid?` returns true on a fresh empty form, no
  fake validator classes ship with the gem.
- Coupling to simple_form is named and isolated to
  `lib/business_logic/simple_form/`. Apps using formtastic /
  `form_with` are unaffected and pay nothing.
- View-level `f.input :foo, required: true | false` overrides
  always win — presentation control is decoupled from validation
  (real cases: wizard step subsets, JS-populated fields,
  controller-prefilled inputs, UI nudge inputs whose Contract rule
  is conditional).
- `simple_form` is not pulled in as a runtime dependency; the
  module is loaded only when the initializer requires it.

**Tests (step 7, redesigned):**

- `BusinessLogic::SimpleForm::Required` is exercised against a
  hand-rolled `StubInput` whose `calculate_required` returns a
  sentinel — proves the module short-circuits to its contract
  result for contract-backed forms, and falls through to `super`
  for everything else.
- `options[:required] = false` honoured even when the contract
  says required. `options[:required] = true` honoured on optional
  contract keys.
- BusinessLogic::Form with no resolvable contract → super.
- Non-Form object → super.

### Documentation

- README "Usage" gains a **Convention-driven architecture**
  subsection (3–5 sentences) covering the Form ↔ Contract naming
  rule and the override hatch.
- README "`business_logic:form`" example gets a one-liner showing
  the inferred `required` marker rendering in `simple_form_for`.
- CHANGELOG entry under a new `## [Unreleased]` heading.

## Sequencing

Each step is its own commit. Red → green → refactor.

1. **Spec scaffolding.** Add `spec/business_logic/form_required_spec.rb`
   with all tests above marked `pending`. Commit:
   `test(form): scaffold required-field inference specs`.
2. **Convention resolution.** Un-pend tests 1–3, implement
   `.contract_class` + `.validates_with_contract`. Commit:
   `feat(form): resolve contract class by convention`.
3. **Required-attribute introspection.** Un-pend tests 4–6,
   implement `.required_attributes` + `.attribute_required?`.
   Commit: `feat(form): infer required attributes from contract`.
4. **Instance delegation.** Un-pend test 7, implement
   `#required?`. Commit: `feat(form): delegate Form#required? to class`.
5. **ActiveModel fallback.** Un-pend test 8, confirm fallback path.
   Commit: `feat(form): keep presence-validator fallback`.
6. **Memoisation.** Un-pend test 9. Commit:
   `perf(form): memoise contract introspection`.
7. **simple_form parity check.** Un-pend test 10. Commit:
   `test(form): assert simple_form hook surface`.
8. **Docs.** README + CHANGELOG. Commit:
   `docs(form): document convention-driven required inference`.

Run `bundle exec rspec` and `bundle exec rubocop` on every commit.
Confirmed in step 1: gem uses rubocop only (no standardrb).

## Manual verification

After step 8, swap the property_management app's
`Gemfile` to a local path:

```ruby
gem "business_logic", path: "../business_logic"
```

Mark `gender` and `preferred_pronouns` as `optional(...)` in
`Contracts::Users::Profile::BasicInfoContract`, render the profile
edit page, confirm those two inputs lose the required marker while
`first_name` / `last_name` / `date_of_birth` keep it. Revert the
Gemfile path before merging the gem PR. App-side wiring lands in a
follow-up.

## Out of scope

- Wiring `property_management` to the new behaviour. Separate PR
  after gem release tag.
- Nested-schema required keys. Only top-level
  `required(:x)` counted in v1.
- Conditional requireds via `rule(:x) { key.failure(...) if ... }`.
- Custom `SimpleForm::Inputs` modules or marker styling.
- Mirroring contract types (`:string`, `:integer`, `gteq?: 18`)
  back onto Form attributes / `simple_form` input types.
- Multi-contract dispatch on a single Form (use Form/Contract
  inheritance or a shared module instead — see README usage).

## Open questions

1. ~~Which dry-schema key_map API is stable…~~ Resolved in step 1:
   `KeyMap` does not encode required/optional. We use
   `contract.new.call({}).errors.to_h.keys` instead — relies only
   on the public `Contract#call` interface, not on internals.
2. Should `attribute_required?` accept symbols, strings, or both?
   simple_form passes symbols; ActiveModel uses strings.
   Decision: accept both, normalise to string internally
   (matches `ActiveModel::Attributes#attribute_names`).
3. Naming of the explicit DSL — `validates_with_contract` is
   verbose. Alternative: `contract Contracts::Foo`. Decision:
   prefer the verbose name; `contract` collides with too many
   project DSLs.
