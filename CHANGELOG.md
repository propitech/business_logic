# Business Logic Changelog

## [Unreleased]

- Add a `Propitech/PreferBeDeleted` cop that flags a Paranoia soft-delete
  assertion written against the `deleted_at` timestamp column
  (`expect(record.deleted_at).to be_present` / `be_nil`, and their negations)
  and autocorrects it to the gem's own `be_deleted` matcher
  (`expect(record).to be_deleted`), preserving polarity. `deleted_at` is the
  storage detail; `be_deleted` states the behaviour Paranoia guarantees, reads
  clearly, and mirrors how the models are queried. The cop keys off the
  `deleted_at` receiver pattern and cannot prove the receiver is a paranoid
  model, so its autocorrect is marked `SafeAutoCorrect: false` — `rubocop -a`
  reports and only an explicit `rubocop -A` applies it.
- Add `BusinessLogic::AbstractMethodError` (a `NoMethodError`, hence a rescuable
  `StandardError`) and a `Propitech/NoNotImplementedError` cop that flags
  `raise NotImplementedError` and autocorrects it to
  `raise BusinessLogic::AbstractMethodError`. `NotImplementedError` is a
  `ScriptError`, not a `StandardError`: a bare `rescue` misses it, and Ruby
  reserves it for features the platform does not implement (a missing
  `fork(2)`). The cop ships enabled; its autocorrect is marked
  `SafeAutoCorrect: false`, because rewriting to a `StandardError` changes what
  surrounding `rescue` clauses catch, so only an explicit `rubocop -A` applies
  it.
- Add a `business_logic:view_component` generator, so the ViewComponent sidecar
  layout every Propitech Rails app shares is scaffolded from one place instead
  of from a per-app copy of the same generator. It writes the component, its
  template, its Lookbook preview with one example template under `preview/`, and
  the component spec — in the documented layout, with no `_component` or
  `_preview` suffix anywhere. Each argument after the name becomes a
  `dry-initializer` `option`. `--skip-preview` and `--skip-test` opt out.
- Declare the gem's runtime dependencies (`activemodel`, `dry-initializer`,
  `dry-monads`) in the gemspec. `require "business_logic"` loads them
  unconditionally, but they previously resolved only through the host app's
  Gemfile — a standalone install (such as qlty's sandboxed RuboCop pulling
  the cops plugin) crashed with `cannot load such file -- active_model`.
- Ship a RuboCop plugin from the gem (enable with `plugins: [business_logic]`
  in a consuming repo's `.rubocop.yml`) carrying two spec cops that enforce the
  result-matcher standard. `Propitech/PreferFailValidation` flags
  `expect(x).not_to succeed_*` and steers to `fail_*.with_error(...)`;
  `Propitech/PreferSucceedValidation` flags `expect(x).not_to fail_*` and steers
  to `succeed_*.with_value(...)`. The negated-sibling form passes for any
  non-matching result and drops the error/value contract; the dedicated matcher
  pins it. Requiring the gem in an application does not load RuboCop — the plugin
  constant is autoloaded only when RuboCop resolves the `plugins:` entry.
- Add two seed-authoring cops to the plugin, scoped to `db/seeds.rb` and
  `db/seeds/**/*.rb`, that hold a seed to two moves: build rows with FactoryBot,
  and fetch a row another seed already built through the shared container.
  `Propitech/SeedUsesFactory` (extracted from `rubocop-propitech`) flags a
  hand-rolled `Model.create`/`create!` and any `Commands::….call` (a command
  runs operation side-effects a seed must not depend on).
  `Propitech/SeedUsesContainer` flags every other direct ActiveRecord
  persistence or lookup verb — on a model class or an instance — and routes it:
  lookup (`find`, `find_by`, …) to `container.get`; creation (any
  `create`/`initialize` verb, e.g. `find_or_create_by`) to `FactoryBot.create`;
  mutation (any `save`/`update`/`destroy`/`delete` verb) to a FactoryBot trait
  that builds the final state. Iteration (`find_each`, block-form `find { … }`),
  the `FactoryBot`/`FactoryGirl` builders, exact `create`/`create!` (owned by
  `SeedUsesFactory`), and non-verbs (`where`, `exists?`) are left alone.
- Add `BaseCommand#new_transaction`, a `requires_new: true` companion to
  `#transaction`. Inside an enclosing transaction it opens a savepoint, so
  a `Failure` (or a DB exception such as a constraint violation) rolls back
  only the nested write and leaves the surrounding transaction usable —
  for a write whose failure must not poison an outer command's transaction.
- Add the `business_logic:wizard_install` generator, which writes a
  `create_wizard_step_states` migration (polymorphic `subject`,
  `wizard_key`, `step_name`, `succeeded_at`, `dismissed_at`, `error`,
  `attempts`, and the unique `(subject, wizard, step)` index) so a host
  app can install the table backing `BusinessLogic::Wizard` with one
  command. README documents the install + per-flow subclassing.
- Add `BusinessLogic::Wizard`, a declarative, DB-backed step runner:
  subclasses declare an ordered `step` DSL and each step's success is
  recorded in `wizard_step_states` via the new
  `BusinessLogic::WizardStepState` model. Verify-only semantics — a step
  runs only once its prerequisites have succeeded, a succeeded step is
  skipped (idempotent) unless re-run via `#reprocess`, and
  `#furthest_incomplete` / `#completed?` drive resume across requests.
  Includes a wizard-level dismissal marker (`WizardStepState.dismiss!` /
  `.dismissed?`). The host owns the table (install it with the
  forthcoming `business_logic:wizard:install` generator); the model is
  required only when ActiveRecord is loaded.
- Split `BusinessLogic::Command` into a bare base
  (`BusinessLogic::Command::Base`, aliased from `BaseCommand`) and
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
