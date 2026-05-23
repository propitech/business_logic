# Business Logic Changelog

## [Unreleased]

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
