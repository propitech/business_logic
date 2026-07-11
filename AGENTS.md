<!-- AGENTS.md — generated. Do not hand-edit this file.                      -->
<!-- Run `bin/agents-render` to regenerate from cache + deltas.              -->
<!-- Baseline: agents-baseline-v1.16.0 (source: agents-baseline-v1.16.0)                  -->
<!-- Project rules: .config/propitech/agents/deltas.md                       -->

# Propitech agent baseline — org-base

Cross-stack house rules for any AI coding agent working in a Propitech
repository. This is the **org-base** layer: it applies regardless of the
project's stack (Rails, Node, …).

> **Managed file — do not hand-edit.** This file is vendored from the
> [Fosa template](https://github.com/propitech/fosa) and verified by
> `bin/agents-check`. Editing it here is drift; the check will fail. Put
> project-specific rules in the root `AGENTS.md` instead (it imports this
> file and overrides it), and re-sync this layer by re-running the template
> (`bin/rails app:template LOCATION=…/fosa/template.rb`).

Sections carry stable `{#slug}` anchors. Reference rules by slug
(`base.md#boundaries`), never by section number — slugs survive reordering.

## Operating principles {#operating-principles}

1. **Plan first for non-trivial work** — see [Plans](#plans). Anything that
   crosses more than two files outside tests, touches the schema, or
   introduces a new abstraction starts with a plan in **Linear**. Agree the
   plan before writing code. {#plan-first}
2. **Small diffs, single concern.** One commit = one logical change.
   Refactors and behaviour changes are separate commits.
3. **No speculative abstractions.** Three similar lines beat a premature
   DSL. Don't design for hypothetical future requirements.
4. **No half-finished implementations.** If you can't finish, leave the
   tree green and document the gap in the plan.
5. **Trust the framework, validate the boundary.** No defensive `nil`
   checks against your own code; do validate user input and third-party
   responses.
6. **Read before writing.** Grep for prior art. The template and sibling
   Propitech repos already encode many decisions.
7. **Ask when reversibility is low.** See [Boundaries](#boundaries).
8. **Never hand-edit a generated artifact.** Regenerate it through its tool
   (schema dumps, generated clients, lockfiles, built baselines) — a manual
   edit drifts the moment the generator runs again.

## Match model to task {#match-model-to-task}

Size the task before you edit, and run it on a model that fits:

- **Architectural planning or schema design** — switch to your strongest
  reasoning model to plan the approach, then drop back down once the shape is
  agreed. Planning is where reasoning depth pays off; see [Plans](#plans).
- **Routine authoring, migrations, and tests** — the faster model is the
  default for code you are writing against an agreed plan. Don't burn the
  high-reasoning tier on mechanical work.

Stated by capability, not by product name: pick the *strongest reasoning* tier
for planning and the *fastest adequate* tier for execution, whatever those are
called in the tool you are running. Compliance with the stack baseline (style,
tests, gates) is non-negotiable at every tier — a faster model is not licence
to skip [Code style](#code-style) or a stack's gates.
## Code style philosophy {#code-style}

The toolchain is opinionated — defer to it. The exact gate commands are
stack-specific; see your stack baseline (e.g. `rails.md#gates`). Regardless
of stack:

- **Never silence.** Fix the code; don't disable a linter rule, append to a
  todo file, or add an ignore comment to make a finding go away. If a rule
  is genuinely wrong for a case, say so and open a plan — don't paper over
  it.
- **Comments: none by default.** Add one only when the *why* is non-obvious
  (hidden constraint, subtle invariant, bug workaround). Never narrate the
  *what* — the code already shows it.
- **Run every gate before reporting done.** A green diff is the bar.
  (`agentic-workflow:gates`)

## Testing {#testing}

- **Every behaviour change ships with a test.** A failing test is a blocker:
  fix the test or the code — never comment it out, never skip or ignore it
  without a linked plan or ticket.
- **Don't mock what you don't own.** Wrap a third-party call behind your own
  adapter and mock the adapter, never the vendor's internals.

Test tooling and stack-specific testing rules live in your stack baseline
(e.g. `rails.md#testing-rails`).
## Workflow {#workflow}

- Branch `ai/<type>/<slug>` (e.g. `ai/feat/class-schedule`) so reviewers
  know an agent drafted the diff; never push to a protected branch.
- **Conventional Commits**: `type(scope): subject`, imperative, ≤72-char
  subject. The body explains *why*, not what — the diff shows what.
- **Pull requests** title with the resolved ticket and a lowercase tag,
  each bracketed — `[PRO-NN][<tag>] <imperative summary>` (tag is any
  lowercase word: `feat`, `fix`, `chore`, `wip`, … — mirrors the commit
  type) — and follow the org template
  (`propitech/.github-private`, auto-filled by GitHub): **Summary** (with a
  `Closes: PRO-NN` line linking the Linear issue), **Solution and changes**,
  **Documentation**, **Developer Notes**. The `Closes:` line lets the
  integration move the issue on merge. Include a screenshot for any
  user-visible change (embed the image the user supplied). CI green before
  review. Match the template headings exactly and resolve repo-local before
  org default. (`agentic-workflow:pr-cadence`, `agentic-workflow:pr-template`)
- **Track work in Linear**, not GitHub issues. Reference the issue id
  (`PRO-NN`) in the PR so the integration auto-links it.
  (`agentic-workflow:linear-update`)
- **Worktrees and the run lifecycle** — drive both with the project's own
  workflow commands; never guess. Create and tear down parallel checkouts with
  `bin/worktree`, never hand-rolled `git worktree add/remove` (hand-rolling
  leaves orphaned services). Run, stop, and reset the app with `mise run start`,
  `mise run stop`, and `mise run reset`. Each checkout already carries its own
  port, database namespace, and services, and those commands read them from the
  worktree — so never infer the server, hand-start a dev process (`rails s`,
  `bin/dev`, …), or hardcode a port. If you don't know how to run a project,
  discover its tasks (`mise tasks`) rather than assuming one.
  (`rails-stack:worktree`) {#worktrees}

## Boundaries — ask before acting {#boundaries}

The agent **must pause and confirm** before:

- Destructive Git ops: `reset --hard`, `push --force`, branch delete,
  `clean -fd`, `checkout .`.
- Schema-touching migrations on existing tables (rename, drop, `NOT NULL`
  add without default).
- Editing secrets or deploy config (credential stores, key material,
  environment files, deploy manifests).
- Adding, removing, or major-bumping a dependency.
- Anything that talks to a remote system: `git push`, opening a PR on
  someone's behalf, deploys, third-party API writes, Slack/Linear posts.
- Disabling a test or a linter/security finding.

The agent **must never**, regardless of permission:

- Run a production deploy command.
- Force-push to a protected branch.
- Merge a PR with `--admin`. It bypasses branch protection — required
  reviews and status checks — to force the change onto the base branch.
  Let the PR merge through its gates: enable auto-merge with
  `gh pr merge --auto --merge` (never `--auto --squash`) so GitHub lands the
  PR itself once every gate passes. Enabling auto-merge is the default final
  step of opening a PR, not an option. (`agentic-workflow:pr-cadence`)
- Commit key material.
- Use `--no-verify`, `--no-gpg-sign`, or otherwise bypass the commit hooks or
  the signature. Every commit must land gpg-signed and verifiable; if commits
  are not signing, fix the gpg-agent rather than committing unsigned.
- Create a commit or file content **server-side** — through the GitHub API
  (contents or git-data endpoints) or a `createCommitOnBranch` GraphQL
  mutation. Server-side commits bypass local signing. Clone, branch, edit,
  and `git commit` locally so the gpg-agent signs it. (`agentic-workflow:signed-commits`)

## Plans (Linear) {#plans}

- The plan/epic lives in **Linear** (Propitech workspace), not the repo: an
  epic is a **project** carrying **Goal**, **Deliverables**, **Sequencing**,
  **Out of scope**, **Open questions** in its description + attached
  documents, broken into one-PR **issues**.
  (`agentic-workflow:plan-first`, `agentic-workflow:decompose-deliverables`)
- **Flagged "Out of scope" / "Deferred" items become Backlog issues** so
  nothing is lost. (`agentic-workflow:flagged-todo`)
- **Every Linear issue carries a Scope label** — exactly one of the `Scope`
  group. One team (`PRO`) holds all work; scope is the cross-product filter.
  Add `Type` and `Discipline` when known. Never create an issue without a
  Scope label.
- Update the plan as the work evolves. A stale plan is worse than no plan.

## Review-driven changes {#review-driven-changes}

When the human is walking the agent through PR review feedback, the loop is
(`agentic-workflow:review-loop`):

1. **One comment per prompt.** Act on that one comment only — no batching,
   no opportunistic cleanup of nearby code.
2. **Challenge before applying.** If the feedback is wrong, incomplete, or
   contradicts house rules, push back with reasoning before touching code.
   A reviewer is not always right; silent compliance is worse than a
   respectful disagreement.
3. **Fix, don't silence.** Address the underlying issue — never bypass a
   finding with an ignore directive. The [Never silence](#code-style) rule
   applies to every gate.
4. **Run the gates every iteration**, plus the relevant test subset, before
   reporting back.
5. **Wait for "satisfied" before committing.** Show the diff and gate
   results, then stop. Commit only when the human explicitly approves — one
   commit per review comment unless told otherwise.
## Agent instructions (this file) {#agent-instructions}

This `AGENTS.md` is a **generated** artifact — a pinned baseline (the managed
sections above) plus this project's deltas. Treat it like any other generated
file (see [Operating principles](#operating-principles)).

- **Don't hand-edit the managed region** or the vendored
  `.config/propitech/agents/<layer>.md` caches: they carry a `DO NOT EDIT`
  banner and are checksum-pinned, so a hand-edit fails the local re-render
  check.
- **Project-specific rules go in `.config/propitech/agents/deltas.md`** — the
  only hand-authored agent surface in this repo. Regenerate with
  `bin/agents-render`, then commit `AGENTS.md` alongside.
- **A machine-local `AGENTS.md.local` is read when present.** If a gitignored,
  untracked `AGENTS.md.local` sits beside `AGENTS.md`, read it in addition to
  this file and let its instructions win on conflict. It is personal and never
  committed — use it for individual or experiment-scoped guidance; shared rules
  belong in `deltas.md` or upstream, not in a file that never lands in git.
- **Pull a newer baseline** with `bin/agents-render --update`, then review the
  `AGENTS.md` diff like a dependency bump.
- The baselines are owned upstream in `propitech/claude-plugins`. To change a
  **shared** rule, change it there (the fragment is the single source), not in
  this generated file.

# Propitech agent baseline — Ruby gem

House rules for a standalone Ruby gem in the Propitech org. This is the
**type-baseline** layer; it sits on top of [`base.md`](base.md) and is
overridden by the project's root `AGENTS.md`.

> **Managed file — do not hand-edit.** Vendored from the agent baseline and
> verified by `bin/agents-check`. Project-specific rules go in the root
> `AGENTS.md`. Re-sync by re-running `bin/agents-render`.

Reference rules by `{#slug}`, never by section number.

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

The universal testing rules are in `base.md#testing`. Ruby gem specifics:

- **Plain RSpec** — no `factory_bot`, no Capybara, no database_cleaner (there
  is no database). Use `let`, `subject`, `shared_examples`, `shared_context`.
- **No mocking what you don't own** — wrap external adapters behind an
  interface; stub the adapter, not the upstream gem.
- **Coverage** — meaningful coverage over metric targets. A spec that asserts
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

- Do not append to `.rubocop_todo.yml` — fix the code instead.
- Do not add `# rubocop:disable` inline comments.
- Do not add `# :reek:` annotations or directory rules in `.reek.yml`.
- A Qlty billing block ("out of minutes") is not a code issue — confirm clean
  locally with `qlty check`; other gates stay binding.



<!-- BEGIN PROJECT DELTAS -->

# business_logic — project agent rules

This file is the **only hand-authored agent surface** in this repository.
The baseline layers above this block are managed (hash-pinned in
`agents.lock.json`); rules you add here win, because the flattened `AGENTS.md`
appends them after the baseline.

After editing this file, run `bin/agents-render` to regenerate `AGENTS.md`.

---

## Mission {#mission}

`business_logic` is a standalone Ruby gem that provides the
`BusinessLogic::Command` base class and dry-rb integrations consumed by
Propitech Rails apps (`property_management`, `dance_school`). It is a library
— no web layer, no database. The public API is a contract; changes that break
callers require a coordinated version bump across all consumers.

## Workflow (business_logic additions) {#workflow-bl}

On top of [base.md#workflow]:

- Branch `ai/<type>/<slug>`; never push to `main`.
- Work is tracked in **Linear** (Propitech workspace, team `PRO`).
- There is no Kamal deploy. A release is a gem publish (`gem push`) after a
  version bump in the gemspec.
- Before a breaking public-API change, validate the gem against
  `../property_management` and `../dance_school`: run their test suites with
  the local gem path-substituted in their `Gemfile`.

## References {#references}

- [README.md](README.md) — public API documentation.
- Consumer repos: `../property_management`, `../dance_school`.
- Work tracking: **Linear** (Propitech workspace, team `PRO`) — see [base.md#plans].

<!-- END PROJECT DELTAS -->
