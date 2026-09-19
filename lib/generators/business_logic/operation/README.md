# Operation generator

The command is the shape the Propitech Rails baseline mandates, and it is what
`business_logic:install` sets up. A [dry-operation](https://dry-rb.org/gems/dry-operation/1.0/)
pipeline is an opt-in: add `gem "dry-operation", "~> 1.0"` to the Gemfile and
write `app/business_logic/application_operation.rb` with
`class ApplicationOperation < Dry::Operation`, as the main README shows under
`business_logic:operation`.

To generate an operation:

```bash
./bin/rails g business_logic:operation CreateUser
```
