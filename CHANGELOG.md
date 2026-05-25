# Business Logic Changelog

## [Unreleased]

- Split `BusinessLogic::Command` into a bare base
  (`BusinessLogic::Command::Base`, aliased from `CommandBase`) and
  a batteries-included default. `BusinessLogic::Command` now
  inherits from `Base` and pre-extends
  `BusinessLogic::Command::DependencyInjection`, a new class-level
  mixin that owns the `.dependency` / `.with` DSL extracted from
  the old monolithic class. Existing apps see no change:
  `class ApplicationCommand < BusinessLogic::Command` still gets
  the same DSL out of the box. Apps that want a stripped-down
  base — no DI — may subclass `BusinessLogic::Command::Base` and
  `extend BusinessLogic::Command::DependencyInjection` per command.
- Add `BusinessLogic::Command::FormBinding`, a class-level mixin
  pre-extended on `BusinessLogic::Command` that exposes
  `.bind_form(form:, **mappings)`. The wrapped command must
  declare `dependency :form`; on call, the form is injected as
  that dependency, each `command_option => form_method` mapping
  is resolved by reading `form.public_send(method)` and passed as
  a keyword, and any `Failure` whose value is a Hash is
  side-routed through `form.assign_errors(failure.to_h)`. The
  returned `Result` is unchanged. Composes with `.with` in either
  order.
- Infer required form fields from the bound dry-validation
  Contract. `BusinessLogic::Form` resolves its Contract by the
  `Forms::Foo -> Contracts::Foo` naming convention (or by an
  explicit `validates_with_contract Contracts::Foo` declaration)
  and exposes `.contract_class`, `.required_attributes`,
  `.attribute_required?`, and instance `#required?` so any form
  builder can read the contract-driven required state. Forms stay
  pure `ActiveModel` objects — no validators are mutated under the
  hood, and `Form#valid?` is unaffected. Falls back to ActiveModel
  presence-validator detection when no Contract resolves, so
  existing forms keep working unchanged.
  See README §"Convention-driven architecture".
- Add an opt-in `simple_form` integration:
  `BusinessLogic::SimpleForm::Required`. Prepending it onto
  `SimpleForm::Inputs::Base` from an initializer makes
  `simple_form_for @form` render the required marker (and
  `aria-required="true"`) for every contract-required attribute,
  while honouring per-input `required: true | false` overrides as
  presentation-only knobs. `simple_form` is not a runtime
  dependency of the gem. See README §"simple_form integration".

## [0.3.0] - 2026-05-23

- Extract `ApplicationForm` logic into a shipped base class:
  `BusinessLogic::Form`. Install template now scaffolds a one-line
  `class ApplicationForm < BusinessLogic::Form; end` — bug fixes and
  feature additions to the bridge logic propagate via `bundle update`
  instead of requiring a re-install in every consumer app.
  Existing 0.2.0 consumers must replace their generated
  `application_form.rb` body with the new one-liner.

## [0.2.0] - 2026-05-23

- Add `ApplicationForm` install template — `ActiveModel::Model` +
  `Attributes` base class that bridges dry-operation `Failure`
  results to Rails form helpers (`simple_form_for @form`). Ships
  `from_params` (strong-params extraction) and `assign_errors`
  (nested-hash → `ActiveModel::Errors` translator).
- Add `business_logic:form` generator. Scaffolds a form under
  `app/business_logic/forms/<name>.rb` + matching spec.
- Expand README with end-to-end usage (operation + contract + form
  - controller + view, including the Turbo 422 caveat).

## [0.1.0] - 2025-11-12

- Initial release
