# Propitech agent baseline: Ruby gem

Ruby-gem rules on top of [`base.md`](base.md); the project's root `AGENTS.md`
overrides both. Managed file, do not hand-edit; see `base.md`. Reference
rules by `{#slug}`, never by section number.

## Stack contract {#stack-contract}

| Concern     | Choice                                                          |
| ----------- | --------------------------------------------------------------- |
| Language    | Ruby 3.4 (pinned in `.ruby-version` + `mise.toml`)              |
| Structure   | Standard gem layout: `lib/`, `spec/`, gemspec, `Gemfile`        |
| Testing     | RSpec                                                           |
| Linting     | RuboCop + `rubocop-rspec`                                       |
| Code smells | Reek                                                            |
| Cross-lang  | Qlty                                                            |

No Rails, no ActiveRecord, no ActiveSupport unless the gemspec explicitly
declares them. Prefer Ruby stdlib (`Comparable`, `Enumerable`, `Forwardable`)
over heavy gem dependencies.

## Testing (Ruby gem) {#testing-ruby-gem}

Ruby gem specifics on top of `base.md#testing`:

- **Plain RSpec.** No `factory_bot`, no Capybara, no database_cleaner (there is
  no database). Use `let`, `subject`, `shared_examples`, `shared_context`.
- **No mocking what you don't own.** Wrap external adapters behind an
  interface; stub the adapter, not the upstream gem.
- **Coverage:** meaningful coverage over metric targets. A spec that asserts
  nothing is worse than no spec.
- The blocker rule from `base.md#testing` applies: never `xit` or comment out
  without a linked ticket.

Run: `bundle exec rspec`

## Gates (Ruby gem) {#gates-ruby-gem}

Run every gate before reporting done:

```bash
bundle exec rubocop          # Ruby style + lint
bundle exec reek lib/        # code smells (lib/ only; spec/ excluded by default)
bundle exec rspec            # tests + coverage
qlty check                   # cross-language gates (same engine as Qlty Cloud)
```

See `base.md#code-style` for the never-silence rule. Specifics:

- Do not append to `.rubocop_todo.yml`; fix the code instead.
- Do not add `# rubocop:disable` inline comments.
- Do not add `# :reek:` annotations, and do not scope a detector to a path or a
  file in `.reek.yml`.
- RuboCop's `Style/Documentation` and Reek's `IrresponsibleModule` (both on
  by default) want a comment on every top-level class or module, but
  `base.md#code-style` reserves a comment for a published surface. Turn the
  check off for the whole project in `.rubocop.yml` or `.reek.yml`, recording
  why there and asking the human first, never as a per-case ignore. Where the
  gem's own top-level classes are its distributed interface, leave the checks
  on and write the comments as API docs.
- A Qlty billing block ("out of minutes") is not a code issue. Confirm clean
  locally with `qlty check`; other gates stay binding.

