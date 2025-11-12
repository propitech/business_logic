# Business logic generator

We use [dry-operation](https://dry-rb.org/gems/dry-operation/1.0/) to organize our business logic.
Eventually we move everything into self-contained operations.

Install the helper files:

```bash
./bin/rails g business_logic:install
```

To generate an operation:

```bash
./bin/rails g business_logic:operation CreateUser
```
