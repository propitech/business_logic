# Project instructions for AI assistants

## Linter violations: fix, never skip

When a linter flags an offence — rubocop, reek, or any other check
surfaced by `qlty check` — **fix the underlying code**. Do not add
file-level exclusions, method-level exclusions, in-line
`# rubocop:disable` / `# reek:` comments, or YAML pragmas that
silence the rule.

Why: skipped violations rot the signal. The next contributor sees
a green check and trusts it. Each pre-existing exclusion already
in `.reek.yml` is a debt entry, not a precedent — do not add more.

How to apply:

- If the rule fires on a method you wrote in this session, refactor
  until the rule passes. Common rescues:
  - `FeatureEnvy` → push the logic into the class the method envies,
    or rebalance refs so self wins.
  - `DuplicateMethodCall` → bind the value to a local once.
  - `UtilityFunction` → either inline back into a caller that does
    use self, or move to a module / class where it makes sense as
    a free function.
  - `InstanceVariableAssumption` → initialise the ivar in
    `initialize` (override with `super` if `Dry::Initializer` or
    similar manages the constructor).
  - `TooManyStatements` → split the method on a real seam, not a
    cosmetic one.
- If the rule fires on pre-existing code you happen to touch,
  prefer fixing it; if scope blocks that, leave the existing
  exclusion alone but do not add a new one.
- If you genuinely believe the rule is wrong for the case at hand
  (rare), surface the trade-off to the user and let them decide —
  do not silently add the exclusion.

## Testing

- `mise exec ruby@3.4.5 -- bundle exec rspec` — all green before
  reporting a task done.
- `qlty check --no-fix lib/ spec/ .reek.yml` — clean.

The repo pins ruby to 3.4.5 (`.ruby-version` + `mise.toml`).
