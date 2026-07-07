# BusinessLogic

A Rails railtie that installs a small set of base classes and
generators for keeping domain orchestration **out of your models and
controllers** and **in one canonical place**: `app/business_logic/`.

[![Ruby CI](https://github.com/propitech/business_logic/actions/workflows/main.yml/badge.svg)](https://github.com/propitech/business_logic/actions/workflows/main.yml)
[![CodeQL](https://github.com/propitech/business_logic/actions/workflows/github-code-scanning/codeql/badge.svg)](https://github.com/propitech/business_logic/actions/workflows/github-code-scanning/codeql)
[![Maintainability](https://qlty.sh/gh/propitech/projects/business_logic/maintainability.svg)](https://qlty.sh/gh/propitech/projects/business_logic)

## What you get

Three app-side base classes generated into your project so you can
add project-wide concerns freely. The form bridge logic ships in the
gem so bug fixes propagate via `bundle update`.

| File                                          | Inherits from                                                        | Use for                                                                                                                                       |
| --------------------------------------------- | -------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `app/business_logic/application_operation.rb` | `Dry::Operation`                                                     | Multi-step pipelines. Step methods return `Success` / `Failure`, with shared data flowing through arguments.                                  |
| `app/business_logic/application_command.rb`   | `BusinessLogic::Command`                                             | OOP service objects for the same use cases. Collaborators/input captured in `#initialize`; `#call` is no-arg and single-shot.                 |
| `app/business_logic/application_contract.rb`  | `Dry::Validation::Contract`                                          | Input validation rules — what is allowed to enter the operation.                                                                              |
| `app/business_logic/application_form.rb`      | `BusinessLogic::Form` (an `ActiveModel::Model` + `Attributes` mixin) | Bridge between Rails form helpers (`simple_form_for @form`) and operation results. Holds submitted attributes; carries `ActiveModel::Errors`. |

Plus four matching generators (`business_logic:operation`,
`business_logic:command`, `business_logic:contract`,
`business_logic:form`) that scaffold a class + its RSpec file in
the right directory.

## Installation

Rails 7+ and RSpec required.

### 1. Add the gem to your `Gemfile`

```ruby
gem "business_logic", github: "propitech/business_logic"
```

### 2. (Optional) Configure paths

Defaults shown — only set these if you want non-standard locations.

```ruby
# config/application.rb
config.business_logic.install_dir = "app/business_logic"
config.business_logic.test_dir    = "spec/business_logic"
```

### 3. Run the installer

```shell
bin/rails generate business_logic:install
```

This copies:

- `app/business_logic/application_operation.rb`
- `app/business_logic/application_command.rb`
- `app/business_logic/application_contract.rb`
- `app/business_logic/application_form.rb`
- `spec/generators_helper.rb`

…and adds these gems to your `Gemfile`:

```ruby
gem "ammeter", "~> 1.1", group: :test
gem "dry-initializer", "~> 3.1"
gem "dry-operation", "~> 1.0"
gem "dry-validation", "~> 1.10"
```

Run `bundle install` to pull them in.

## Usage

### `business_logic:operation` — a domain verb

```shell
bin/rails generate business_logic:operation CreateUser
```

Creates:

- `app/business_logic/operations/create_user.rb`
- `spec/business_logic/operations/create_user_spec.rb`

A typical operation pipelines steps and returns a monad. Inject the
form, contract, and any side-effect adapters via `option`:

```ruby
module Operations
  class CreateUser < ApplicationOperation
    option :contract, default: -> { Contracts::CreateUser.new }
    option :mailer,   default: -> { UserMailer }

    def call(form:)
      attrs = step validate(form)
      user  = step persist(form, attrs)
      step notify(user)
      Success(user)
    end

    private

    def validate(form)
      result = contract.call(form.attributes.symbolize_keys)
      return Success(result.to_h) if result.success?

      form.assign_errors(result.errors.to_h)
      Failure(form)
    end

    def persist(form, attrs)
      user = User.new(attrs)
      return Success(user) if user.save

      form.assign_errors(user.errors.to_hash)
      Failure(form)
    end

    def notify(user)
      mailer.welcome(user).deliver_later
      Success(user)
    end
  end
end
```

### `business_logic:command` — an OOP service object

```shell
bin/rails generate business_logic:command CreateUser
```

Creates:

- `app/business_logic/commands/create_user.rb`
- `spec/business_logic/commands/create_user_spec.rb`

A Command is the OOP sibling of Operation: same public interface
(`#call` returns a `Dry::Monads::Result`), different internal
shape. Collaborators and input live on the instance, set in
`#initialize` via `Dry::Initializer`. Two DSLs are always
available:

- `param :name` — positional input data.
- `option :name` — keyword input data.

`BusinessLogic::Command` is the batteries-included base —
`ApplicationCommand` inherits from it directly. It pre-extends
two class-level mixins so every subclass also gets:

- **`BusinessLogic::Command::DependencyInjection`** —
  `dependency :name, default: -> { ... }` (sugar for `option`
  plus registration in the per-class dependency set) and
  `.with(**overrides)` (per-call collaborator overrides,
  validated against the declarations).
- **`BusinessLogic::Command::FormBinding`** —
  `.bind_form(form:, **mappings)` for wiring a
  `BusinessLogic::Form` into a call. See
  [Binding a Form to a Command](#binding-a-form-to-a-command) below.

Apps that want a stricter base — no DI, no form binding — may
subclass `BusinessLogic::Command::Base` directly and `extend`
either mixin per command.

`#call` takes no arguments and is single-shot — a second
invocation raises `BusinessLogic::Command::AlreadyCalled`.
Subclasses override `#execute`, not `#call`; the base wraps the
override with the guard.

```ruby
module Commands
  class CreateUser < ApplicationCommand
    option     :user
    option     :form
    dependency :contract, default: -> { Contracts::CreateUserContract.new }
    dependency :mailer,   default: -> { UserMailer }

    def execute
      attrs   = yield validate
      record  = yield persist(attrs)
      notify(record)
      Success(record)
    end

    private

    def validate
      result = contract.call(form.attributes.symbolize_keys)
      return Success(result.to_h) if result.success?

      form.assign_errors(result.errors.to_h)
      Failure(form)
    end

    def persist(attrs)
      user.assign_attributes(attrs)
      return Success(user) if user.save

      form.assign_errors(user.errors.to_hash)
      Failure(form)
    end

    def notify(record)
      mailer.welcome(record).deliver_later
    end
  end
end
```

Call sites:

```ruby
# default dependencies
Commands::CreateUser.call(user:, form:)

# explicit construction
Commands::CreateUser.new(user:, form:).call

# override one dependency for this call only
Commands::CreateUser
  .with(contract: Contracts::AdminCreateUserContract.new)
  .call(user:, form:)

# overriding a non-dependency (input data) raises
Commands::CreateUser.with(user: other_user)
# => BusinessLogic::Command::UnknownDependency: ... [:user] not in
#    declared dependencies [:contract, :mailer]
```

The `.with(...)` guard prevents accidental input clobbering when
input data is declared via `option` rather than `param`.

#### Binding a Form to a Command

When a controller already has a `BusinessLogic::Form` holding
submitted attributes, the `FormBinding` mixin lets you wire it
into the Command call without the command knowing about Forms.
The Command declares `dependency :form` and accepts the
attributes via a plain `option`:

```ruby
module Commands
  class UpdateUser < ApplicationCommand
    dependency :form
    dependency :contract, default: -> { Contracts::UpdateUserContract.new }
    option     :user
    option     :user_attributes

    def execute
      attrs = yield validate(user_attributes)
      save(attrs)
    end

    private

    def validate(attrs)
      result = contract.call(attrs.symbolize_keys)
      result.success? ? Success(result.to_h) : Failure(result.errors.to_h)
    end

    def save(attrs)
      user.update(attrs) ? Success(user) : Failure(user.errors.to_hash)
    end
  end
end
```

Controllers call it through `.bind_form(form:, **mappings)`,
where each `command_option => form_method` mapping is resolved
lazily by reading `form.public_send(method)` at call time:

```ruby
result = Commands::UpdateUser
  .bind_form(form: @form, user_attributes: :attributes)
  .call(user: @user)

if result.success?
  redirect_to result.value!, notice: t(".updated")
else
  render :edit, status: :unprocessable_content
end
```

The proxy:

1. Injects the form as the `:form` dependency.
2. Calls `form.public_send(:attributes)` and passes it as
   `user_attributes:`.
3. On `Failure` whose value is a Hash, calls
   `@form.assign_errors(failure.to_h)` as a side effect — `simple_form_for @form`
   then renders the per-field error markup. The returned `Result`
   is unchanged, so callers can still inspect `result.failure`
   directly.
4. On `Failure` whose value is anything other than a Hash, the
   form is left untouched and the result is returned as-is.

Composes with `.with` in either order:

```ruby
Commands::UpdateUser
  .with(contract: Contracts::AdminUpdateUserContract.new)
  .bind_form(form: @form, user_attributes: :attributes)
  .call(user: @user)

# equivalent
Commands::UpdateUser
  .bind_form(form: @form, user_attributes: :attributes)
  .with(contract: Contracts::AdminUpdateUserContract.new)
  .call(user: @user)
```

#### Command vs Operation — when to pick which

Both return `Dry::Monads::Result` and can call each other as
steps. Pick on shape:

- **Operation** when the use case is a linear pipeline of pure
  transforms with data flowing through method arguments.
  Stateless across calls.
- **Command** when there are several collaborators (mailer,
  contract, repository, policy) or several helper methods
  sharing the same input. Keeping those as instance state
  reads better and avoids the `FeatureEnvy` /
  `UtilityFunction` smells that plain step methods attract
  when they keep receiving the same arguments.

### `business_logic:contract` — input validation rules

```shell
bin/rails generate business_logic:contract CreateUser
```

Creates:

- `app/business_logic/contracts/create_user.rb`
- `spec/business_logic/contracts/create_user_spec.rb`

```ruby
module Contracts
  class CreateUser < ApplicationContract
    params do
      required(:email).filled(:string, format?: URI::MailTo::EMAIL_REGEXP)
      required(:age).filled(:integer, gteq?: 18)
    end
  end
end
```

`contract.call(attrs).errors.to_h` returns the nested hash
`ApplicationForm#assign_errors` consumes.

### `business_logic:form` — the view-facing surface

```shell
bin/rails generate business_logic:form CreateUser
```

Creates:

- `app/business_logic/forms/create_user.rb`
- `spec/business_logic/forms/create_user_spec.rb`

```ruby
module Forms
  class CreateUser < ApplicationForm
    # Optional: override only when the form binds to a non-self
    # param key, e.g. when the form maps to an existing AR model's
    # form scope.
    # def self.model_name = ActiveModel::Name.new(self, nil, "user")

    attribute :email, :string
    attribute :age, :integer
  end
end
```

`BusinessLogic::Form` (inherited via `ApplicationForm`) ships with
two helpers:

- **`.from_params(params, key: model_name.param_key)`** — strong-params
  extraction. Permits only declared attributes.
- **`#assign_errors(source)`** — translates a nested errors hash
  (from a contract, an Active Record model, anything shaped like
  `{attr => [msgs]}` / `{attr => {nested => [msgs]}}`) into
  `ActiveModel::Errors`. Unknown keys land on `:base`.

`ApplicationForm` itself is one line:

```ruby
class ApplicationForm < BusinessLogic::Form
end
```

Add project-wide hooks (i18n, custom param extraction, shared
validations) there. Bridge logic stays in the gem so a `bundle
update` is the only step needed to pick up fixes.

### `business_logic:wizard_install` — a multi-step flow

For DB-backed, multi-step flows (onboarding, setup wizards), the gem
ships `BusinessLogic::Wizard`: a verify-only step runner whose progress
lives in a `wizard_step_states` table rather than the session.

Install the table once:

```shell
bin/rails generate business_logic:wizard_install
bin/rails db:migrate
```

Then declare a wizard per flow. Each `step` runs in instance context and
returns a dry-monads `Result` (typically a command's):

```ruby
class OrganizationSetup < BusinessLogic::Wizard
  step(:identity) { |input| SaveIdentity.call(organization: subject, **input) }
  step(:contacts) { |input| SaveContacts.call(organization: subject, attrs: input) }
  step(:details)  { |input| Complete.call(organization: subject, attrs: input) }
end

wizard = OrganizationSetup.new(organization)
wizard.process(:identity, attrs)   # runs it; records success
wizard.process(:contacts, attrs)   # only runs once :identity has succeeded
wizard.furthest_incomplete         # => :details — drives resume
wizard.completed?                  # => true once every step has succeeded
```

Semantics:

- **Verify-only prerequisites** — a step runs only once every prior step
  has succeeded; prerequisites are checked, never re-executed.
- **Idempotent** — a succeeded step is skipped (`process` returns
  `Success(:skipped)`) unless re-run via `#reprocess` (re-submit / edit).
- **Resume** — `#furthest_incomplete` and `#completed?` read straight
  from `wizard_step_states`, so progress survives across requests and
  sessions. `subject` is any persisted record (polymorphic).
- **Dismissal** — `BusinessLogic::WizardStepState.dismiss!(subject:,
wizard_key:)` / `.dismissed?(...)` record a wizard-level "don't remind
  me" marker on a reserved row that `#completed?` ignores.

`BusinessLogic::WizardStepState` is loaded only when ActiveRecord is
present; the engine itself is plain Ruby.

## End-to-end pattern

Controllers stay dispatchers. Build the form, call the operation,
branch on the monad, re-render with the form on failure.

```ruby
class UsersController < ApplicationController
  def create
    form   = Forms::CreateUser.from_params(params)
    result = Operations::CreateUser.new.call(form: form)

    if result.success?
      redirect_to result.value!, notice: t(".created")
    else
      @form = result.failure
      render :new, status: :unprocessable_content
    end
  end
end
```

```erb
<%# app/views/users/new.html.erb %>
<%= simple_form_for @form, url: users_path do |f| %>
  <%= f.input :email %>
  <%= f.input :age %>
  <%= f.submit %>
<% end %>
```

`simple_form` reads `@form.errors[:email]` natively, so per-field
error messages and `aria-invalid` markup show up without any custom
view logic. With the optional [simple_form
integration](#simple_form-integration) installed, it also renders
the **required marker** (and `aria-required="true"`) for every
attribute the bound Contract declares as `required(...)` — without
you repeating that on the Form. `optional(...)` keys render as
optional.

**Turbo note:** Turbo Drive discards HTML responses to non-GET
requests unless the status is in the 4xx/5xx range. Always render
the error page with `status: :unprocessable_content` (HTTP 422) — a
default 200 will leave the user staring at the unchanged page.

## Convention-driven architecture

This gem prefers **convention over configuration**. The three
generators (`operation`, `contract`, `form`) drop classes into
matching namespaces so that any two of the three can find the third
by name alone:

```text
Operations::CreateUser   ── orchestrates ─▶  Contracts::CreateUser
                                                   │
Forms::CreateUser        ── validated by ─────────┘
```

The Form ↔ Contract naming rule:

```text
Forms::Users::Profile::BasicInfoForm
        │                  │
        │                  └── strip trailing "Form" ⇒ "BasicInfo"
        └── swap `Forms` segment for `Contracts`
                                  ↓
Contracts::Users::Profile::BasicInfoContract
```

Two payoffs:

1. **Less duplication.** The Contract is the only place that knows
   what is required. Forms stop drifting from it. The
   [simple_form integration](#simple_form-integration) reads the
   inferred required state for every input automatically.
2. **Predictable navigation for humans _and_ AI agents.** Given any
   Form, both can locate the Contract by name. No registry to
   grep, no DSL to memorise.

### Sharing a Form/Contract across operations

When two operations need the same fields, lean on ordinary Ruby
inheritance — no special multi-contract dispatch is needed:

```ruby
class Contracts::User < ApplicationContract
  params { required(:email).filled(:string) }
end

class Contracts::CreateUser < Contracts::User
  params { required(:password).filled(:string) }
end

class Forms::User < ApplicationForm
  attribute :email, :string
end

class Forms::CreateUser < Forms::User
  attribute :password, :string
end
```

Or extract the shared fields into a module and `include` it into
both Forms — same pattern, same convention applies to the
subclasses.

### Opting out

If a Form's namespace cannot follow the convention (renamed
namespaces, shared Contract across unrelated Forms, etc.) declare
the binding explicitly inside the Form class:

```ruby
class Forms::Onboarding::Step1 < ApplicationForm
  validates_with_contract Contracts::Users::CreateUser

  attribute :email, :string
end
```

Or opt out of the inferred required marker on a per-input basis the
usual simple_form way:

```erb
<%= f.input :email, required: false %>
```

The view-level override only controls the rendered marker (asterisk

- `aria-required` + the HTML5 `required` attribute). Server-side
  validation still runs through the Contract — passing
  `required: false` does not loosen what the Contract enforces. Apply
  it where presentation and validation legitimately differ:
  multi-step wizards rendering a partial field set, JS-populated
  fields, controller-prefilled inputs, etc.

## simple_form integration

Opt in from a Rails initializer:

```ruby
# config/initializers/simple_form.rb
require "business_logic/simple_form/required"

SimpleForm::Inputs::Base.prepend(BusinessLogic::SimpleForm::Required)
```

That single prepend teaches every input to consult the bound
Contract when computing the required state. The gem does not pull
`simple_form` as a runtime dependency, and Forms remain pure
`ActiveModel` objects (no fake validators are installed). Apps that
use formtastic or `form_with` are unaffected.

Behaviour:

- Object **is** a `BusinessLogic::Form` **and** a Contract resolves
  (via convention or `validates_with_contract`) → required state
  comes from the Contract's `required(...)` keys.
- `f.input :foo, required: true | false` is always honoured —
  presentation override wins.
- Object is anything else (plain models, AR, formtastic-style
  decorators) → control falls through to simple_form's stock
  `calculate_required`, so existing behaviour is unchanged.

## RSpec matchers

`require "business_logic/matchers"` in your `spec_helper.rb` to get
three composable matchers for monadic results:

```ruby
expect(Contracts::CreateUser.new.call(email: "bad")).to fail_contract.with_messages(email: ["invalid"])
expect(Operations::CreateUser.new.call(form: form)).to succeed_operation
expect(Commands::CreateUser.call(user, form)).to succeed_command
```

Aliases: `succeed_contract` / `succeed_validation` / `succeed_operation` / `succeed_command`;
`fail_contract` / `fail_validation` / `fail_operation` / `fail_command`.

## RuboCop cops

The gem ships a RuboCop plugin that enforces the matcher standard so a
failing (or succeeding) result is asserted with the dedicated matcher
and its payload, never a negated sibling. Enable it in a consuming
repo's `.rubocop.yml`:

```yaml
plugins:
  - business_logic
```

| Cop                                 | Flags                        | Steers to                   |
| ----------------------------------- | ---------------------------- | --------------------------- |
| `Propitech/PreferFailValidation`    | `expect(x).not_to succeed_*` | `fail_*.with_error(...)`    |
| `Propitech/PreferSucceedValidation` | `expect(x).not_to fail_*`    | `succeed_*.with_value(...)` |

Both cops default to `Include: '**/*_spec.rb'`. Asserting failure with
the negated success matcher (`not_to succeed_validation`) passes for
_any_ non-success — including the wrong error — so it silently drops
the error contract; the `fail_*.with_error(...)` form pins the exact
failure. The success direction is symmetric.

## Seed registry

`BusinessLogic::Seed` is a dependency-ordered, idempotent registry for
`db/seeds`. Each seed is a subclass implementing `#call`; the registry
discovers every subclass, orders them so each one's declared
dependencies run first, and runs each once against a shared container.
Progress is written through `#say` to the container's IO, so a test can
capture it instead of writing to `$stdout`. It is plain Ruby — no Rails
or ActiveSupport — so the host app supplies the seed directory and any
app-specific constants by subclassing.

Alias the base in your app and point it at your seed directory:

```ruby
# app/lib/seed.rb
class Seed < BusinessLogic::Seed
  DEV_PASSWORD = "password123"
  def self.default_seeds_dir = Rails.root.join("db/seeds")
end
```

Write each seed as a subclass, declaring what must run before it and
passing records forward through the container:

```ruby
# db/seeds/users.rb
module Seeds
  class Users < Seed
    def call
      say "Seeding users..."
      container.set(:admin, create_admin)
    end
  end
end

# db/seeds/company.rb
module Seeds
  class Company < Seed
    depends_on :users

    def call
      say "Seeding company..."
      Company.create!(owner: container.get(:admin))
    end
  end
end
```

`depends_on :users` resolves to the sibling `Seeds::Users` at ordering
time, so declaration order across files does not matter. A cycle raises
`BusinessLogic::Seed::CircularDependencyError`.

Run them from `db/seeds.rb`:

```ruby
# db/seeds.rb — loads db/seeds/*.rb, orders by dependency, runs each once.
Seed.run_all
```

`run_all` loads the files under `default_seeds_dir` and runs only the
concrete seeds (subclasses that implement `#call`), so the abstract
alias is skipped. Pass `Seed.run_all(dir: nil)` when the files are
already loaded, or `Seed.run(seed_classes, container)` to run a specific
set — the entry point tests use this to stay off `$stdout`.

## Development

```shell
bin/setup       # install gem deps
rake spec       # run the tests
bin/console     # IRB with the gem preloaded
```

Release a new version: bump `lib/business_logic/version.rb`, then
`bundle exec rake release` (tags, pushes, publishes to RubyGems).

## Contributing

Bug reports and pull requests welcome on GitHub at
<https://github.com/propitech/business_logic>. Contributors are
expected to follow the [code of conduct](https://github.com/propitech/business_logic/blob/main/CODE_OF_CONDUCT.md).

## License

[MIT](https://opensource.org/licenses/MIT).
