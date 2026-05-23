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
| `app/business_logic/application_operation.rb` | `Dry::Operation`                                                     | Multi-step use cases. Steps return `Success` / `Failure`.                                                                                     |
| `app/business_logic/application_contract.rb`  | `Dry::Validation::Contract`                                          | Input validation rules — what is allowed to enter the operation.                                                                              |
| `app/business_logic/application_form.rb`      | `BusinessLogic::Form` (an `ActiveModel::Model` + `Attributes` mixin) | Bridge between Rails form helpers (`simple_form_for @form`) and operation results. Holds submitted attributes; carries `ActiveModel::Errors`. |

Plus three matching generators (`business_logic:operation`,
`business_logic:contract`, `business_logic:form`) that scaffold a
class + its RSpec file in the right directory.

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
view logic.

**Turbo note:** Turbo Drive discards HTML responses to non-GET
requests unless the status is in the 4xx/5xx range. Always render
the error page with `status: :unprocessable_content` (HTTP 422) — a
default 200 will leave the user staring at the unchanged page.

## RSpec matchers

`require "business_logic/matchers"` in your `spec_helper.rb` to get
three composable matchers for monadic results:

```ruby
expect(Contracts::CreateUser.new.call(email: "bad")).to fail_contract.with_messages(email: ["invalid"])
expect(Operations::CreateUser.new.call(form: form)).to succeed_operation
```

Aliases: `succeed_contract` / `succeed_validation` / `succeed_operation`;
`fail_contract` / `fail_validation` / `fail_operation`.

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
