# 0002 — `BusinessLogic::Command`: OOP-friendly sibling of Operation

**Status:** landed (with `dependency` DSL — see §"`dependency` DSL")
**Owner:** @hery
**Created:** 2026-05-25

## Goal

Introduce a second domain-verb primitive — `BusinessLogic::Command` —
that complements `Dry::Operation` for use cases where an OOP,
stateful service object reads better than a functional pipeline of
pure step methods.

The two primitives share a public instance interface (`#call`
returning a `Dry::Monads::Result`) so they can call each other as
steps in either direction. The difference is _internal shape_:

| Aspect                       | `Dry::Operation` (existing)                             | `BusinessLogic::Command` (new)                                |
| ---------------------------- | ------------------------------------------------------- | ------------------------------------------------------------- |
| Style                        | Functional pipeline, `step ...` between pure transforms | OOP service object, collaborators held as instance state      |
| `#call`                      | Takes input args, returns `Result`                      | Takes **no args**, returns `Result`                           |
| State                        | Stateless across calls                                  | Stateful — `param`/`option` set in `#initialize`, single-shot |
| Override point               | `def call(input)`                                       | `def execute` (base wraps with guard)                         |
| Class shortcut               | `Op.new.call(input)`                                    | `Command.call(*p, **kw)` = `new(*p, **kw).call`               |
| Option override at call site | n/a (deps usually via `option` with default lambda)     | `Command.with(option: x).call(*p, **kw)`                      |
| Re-call                      | Allowed                                                 | Raises `AlreadyCalled`                                        |

## Why a second primitive

`Dry::Operation`'s pipeline-of-step-methods shape encourages two
reek smells we keep hitting:

- **FeatureEnvy** — step methods receive the same arg(s) repeatedly
  and chain into them (`input.user.profile.foo`).
- **UtilityFunction** — step methods that are pure data
  transformations and never touch `self`, flagged as "should be
  a class method".

Both go away when collaborators live as instance state set in the
initializer: `self.user`, `self.contract`, `self.mailer` reads
instead of `input[:user]`, and helper methods naturally touch
`self`, satisfying UtilityFunction.

We keep `Dry::Operation` for genuinely-pipelined transforms
(validate → persist → notify with no carried collaborators). We add
`Command` for the OOP cases.

Inspiration: [collectiveidea/interactor](https://github.com/collectiveidea/interactor).
That gem is unmaintained and bundles features we do not need
(`organizer`, `rollback`, mutable context). We ship a smaller,
dry-monads-native version.

## Naming

`Command` — the GoF Command pattern: encapsulate a request as an
object, exposing a single `execute` (`call`) entry point, with
arguments captured in the object's state. Matches our constraints
exactly (no-arg `call`, single-shot, stateful).

User-side namespace: `Commands::` (plural, matching
`Operations::` / `Contracts::` / `Forms::`).

## Deliverables

### Gem code

1. `lib/business_logic/command.rb` — `BusinessLogic::Command` base
   class.
   - `extend Dry::Initializer` — `param :foo` for input data,
     `option :bar, default: -> { Dep.new }` for collaborators.
   - `include Dry::Monads[:result, :do]` — `Success` / `Failure`
     constructors + `Do` notation (`yield`) for composing nested
     `Result`-returning calls.
   - `#call` — no args. Raises `AlreadyCalled` if called twice.
     Sets `@__called`, delegates to `#execute`.
   - `#execute` — abstract, `raise NotImplementedError`. Subclass
     overrides this and returns a `Result`.
   - `def self.call(*p, **kw)` — sugar for `new(*p, **kw).call`.
   - `def self.with(**option_overrides)` — returns a `Proxy`
     instance carrying the override hash. `Proxy#call(*p, **kw)`
     instantiates the command with `(*p, **kw, **overrides)` then
     calls it.
   - `class AlreadyCalled < StandardError`.

2. `lib/business_logic/command/proxy.rb` — private constant.
   Minimal delegator: holds `command_class` + `overrides`, exposes
   `#call(*p, **kw)` only. No instance `.with` chaining (out of
   scope for now — `Klass.with(a: 1, b: 2).call` covers the
   common case). Marked `private_constant :Proxy`.

3. Wiring:
   - `lib/business_logic.rb` requires `business_logic/command`.
   - `lib/business_logic/matchers.rb` adds aliases
     `succeed_command` / `fail_command`.

### App-side scaffolding

1. `lib/generators/business_logic/install/templates/application_command.rb.tt`
   — copies to `app/business_logic/application_command.rb`:

   ```ruby
   # frozen_string_literal: true
   class ApplicationCommand < BusinessLogic::Command
   end
   ```

2. `lib/generators/business_logic/install/install_generator.rb`
   — copies `application_command.rb` alongside the other base
   files.

3. `lib/generators/business_logic/command/` —
   - `command_generator.rb` (mirrors `operation_generator.rb`)
   - `USAGE`
   - `templates/command.rb.erb.tt`
   - `templates/command_spec.rb.erb.tt`

### Tests

1. `spec/business_logic/command_spec.rb` — base behaviour:
   - abstract `#execute` raises `NotImplementedError`.
   - second `#call` raises `BusinessLogic::Command::AlreadyCalled`.
   - `.call(*p, **kw)` class shortcut == `.new(*p, **kw).call`.
   - `.with(opt: x).call(*p, **kw)` merges override; default
     `option` lambda is shadowed.
   - return monad usable as `step` inside `Dry::Operation`.
   - `yield` inside `#execute` short-circuits on `Failure`
     (Do-notation smoke test).
2. `spec/generators/business_logic/command_generator_spec.rb` —
   scaffolded paths + class declaration mirror operation generator
   spec.
3. `spec/support/application_command.rb` — `ApplicationCommand <
BusinessLogic::Command` for tests that exercise generated
   shape.

### Docs

1. `README.md` — extend the generator table with the `Command`
   row, add a "When to pick Command vs Operation" subsection
   under Usage, and document `.with(...)` option override.

## Example usage

```ruby
class Commands::Users::CreateAccount < ApplicationCommand
  param  :user
  param  :form
  option :contract, default: -> { Contracts::Users::CreateAccountContract.new }
  option :mailer,   default: -> { UserMailer }

  def execute
    attrs   = yield validate
    persisted = yield persist(attrs)
    notify(persisted)
    Success(persisted)
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
```

Call sites:

```ruby
# default contract + mailer
Commands::Users::CreateAccount.call(user, form)

# explicit construction
Commands::Users::CreateAccount.new(user, form).call

# override one option at the call site
Commands::Users::CreateAccount
  .with(contract: Contracts::Users::AdminCreateAccountContract.new)
  .call(user, form)
```

Inside a `Dry::Operation` step:

```ruby
def call(user:, form:)
  persisted = step Commands::Users::CreateAccount.new(user, form).call
  Success(persisted)
end
```

Inside a `Command` calling an `Operation`:

```ruby
def execute
  attrs = yield Operations::Validate.new.call(form)
  ...
end
```

## Single-shot semantics

`#call` raises `BusinessLogic::Command::AlreadyCalled` on the
second invocation. Implementation:

```ruby
def call
  raise AlreadyCalled, "#{self.class} already called" if @__called

  @__called = true
  execute
end
```

The flag lives on the instance — no class-level state, naturally
thread-safe (a single instance is not shared across threads in
typical Rails request handling; if a caller does share one, the
guard still behaves correctly modulo a benign race where two
threads might both pass the check before either sets the flag —
acceptable for the v1 scope).

## `.with(...)` proxy

```ruby
class Command
  def self.with(**overrides)
    Proxy.new(self, overrides)
  end

  class Proxy
    def initialize(command_class, overrides)
      @command_class = command_class
      @overrides = overrides
    end

    def call(*params, **keyword_params)
      @command_class.new(*params, **keyword_params, **@overrides).call
    end
  end
  private_constant :Proxy
end
```

No instance-level `.with` (callers cannot meaningfully
`Klass.new(...).with(...)`; the instance has already bound its
options at `new` time). No chained `proxy.with(...)` (extend
later if needed).

## Reek posture

- Collaborators reached via `self.contract`, `self.mailer`, etc.
  (synthesised by `Dry::Initializer`), keeping every helper
  method touching `self` — no `UtilityFunction` triggers.
- `param`s expose input data as accessors so helpers read
  `user`/`form`, not `args[:user]` — no `FeatureEnvy`.
- `Proxy` is small, single-purpose, holds two ivars — passes
  default reek.

## `dependency` DSL

Added after the initial implementation to support `option`-as-input
without losing the safety of a constrained `.with(...)` API.

Problem: when input data is declared via `option` (keyword) rather
than `param` (positional), `.with(name: value).call(name: other)`
would silently clobber the caller's keyword because both flow into
the same `new(**kw, **overrides)` constructor — making input-vs-dep
indistinguishable to `.with`.

Solution: introduce `dependency :name, default: -> { ... }` as a
thin wrapper around `option` that also registers the name in a
class-level `dependencies` Set. `.with(**overrides)` validates
`overrides.keys ⊆ dependencies` and raises
`BusinessLogic::Command::UnknownDependency` on any mismatch.

```ruby
class Commands::CreateUser < ApplicationCommand
  option     :user           # input
  option     :form           # input
  dependency :contract, default: -> { Contracts::CreateUserContract.new }
end

Commands::CreateUser.with(contract: Other.new).call(user:, form:)  # OK
Commands::CreateUser.with(user: x)                                 # raises
```

Inheritance: `dependencies` is copy-on-write per class — subclass
gets a duplicate of the parent's set on first read, additions stay
local.

`dependency` semantically equals `option` + register. Inputs may
still be declared as `param` (positional) or `option` (keyword).
The default scaffold encourages `option` + `dependency` for the
all-keyword OOP style.

## Out of scope (deferred)

- `rollback` callback / multi-command organiser (the
  collectiveidea features). Add later as an extension when a
  concrete need surfaces.
- Auto-binding `Contracts::Foo` by convention (mirroring
  `Forms::Foo → Contracts::Foo`). Keep contract injection
  explicit via `option :contract, default: ...` for now.
- Per-attribute `param`-level coercion (not needed — input data
  comes from a Form which already has coerced types).
- Instance-level `.with` and chained `proxy.with(...)`.
