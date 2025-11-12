# BusinessLogic

Set of generators to help you build your Rails application business logic.

[![Ruby CI](https://github.com/propitech/business_logic/actions/workflows/main.yml/badge.svg)](https://github.com/propitech/business_logic/actions/workflows/main.yml)
[![CodeQL](https://github.com/propitech/business_logic/actions/workflows/github-code-scanning/codeql/badge.svg)](https://github.com/propitech/business_logic/actions/workflows/github-code-scanning/codeql)
[![Maintainability](https://qlty.sh/gh/propitech/projects/business_logic/maintainability.svg)](https://qlty.sh/gh/propitech/projects/business_logic)

## Installation

This gem only works with Rails 7+ and RSpec.

### Add to your `Gemfile`

```ruby
group :development, :test do
  gem "business_logic", github: "propitech/business_logic"
end
```

### Configure paths

In your `config/application.rb` file, add the following lines:

```ruby
  config.business_logic.install_dir = "app/business_logic" # default if not set
  config.business_logic.test_dir = "spec/business_logic" # default if not set
```

### Install boilerplates

```shell
bin/rails generate business_logic:install
```

## Usage

### Operations

```text
Description:
    Generates a new operation and its spec file.

Example:
    bin/rails generate business_logic:contract ValidateStudent

    This will create:
        app/business_logic/contracts/validate_student.rb
        spec/business_logic/contracts/validate_student_spec.rb
```

### Contracts

```text
Description:
    Generates a new contract and its spec file.

Example:
    bin/rails generate business_logic:contract ValidateStudent

    This will create:
        app/business_logic/contracts/validate_student.rb
        spec/business_logic/contracts/validate_student_spec.rb
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you
to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`,
which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/propitech/business_logic>.
This project is intended to be a safe, welcoming space for collaboration,
and contributors are expected to adhere to the [code of conduct](https://github.com/propitech/business_logic/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the BusinessLogic project's codebases, issue trackers, chat rooms and mailing lists
is expected to follow the [code of conduct](https://github.com/propitech/business_logic/blob/main/CODE_OF_CONDUCT.md).
