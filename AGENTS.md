<!-- AGENTS.md — generated. Do not hand-edit this file.                      -->
<!-- Run `bin/agents-render` to regenerate from cache + deltas.              -->
<!-- Baseline: agents-baseline-v2.1.0 (source: agents-baseline-v2.1.0)                  -->
<!-- Project rules: .config/propitech/agents/deltas.md                       -->

# Propitech agent baseline — org-base

Cross-stack house rules for any AI coding agent in a Propitech repository. This
**org-base** layer applies whatever the project's stack.

> **Managed file — do not hand-edit.** Vendored from the
> [Fosa template](https://github.com/propitech/fosa) and verified by
> `bin/agents-check`, which fails on a hand-edit. Project-specific rules go in
> the root `AGENTS.md`, which imports and overrides this file; re-sync by
> re-running the template
> (`bin/rails app:template LOCATION=…/fosa/template.rb`).

Reference a rule by its `{#slug}` anchor (`base.md#boundaries`), never by
section number.

## Operating principles {#operating-principles}

1. **Plan first for non-trivial work** — more than two non-test files, a schema
   change, or a new abstraction starts with a plan agreed in **Linear**
   ([Plans](#plans)). {#plan-first}
2. **Small diffs, single concern.** One commit is one logical change; refactor
   and behaviour change are separate commits.
3. **No speculative abstractions.** Three similar lines beat a premature DSL.
4. **No half-finished implementations.** Where you cannot finish, leave the tree
   green and record the gap in the plan.
5. **Trust the framework, validate the boundary.** No defensive `nil` checks
   against your own code; validate user input and third-party responses.
6. **Read before writing.** Grep for prior art.
7. **Ask when reversibility is low** ([Boundaries](#boundaries)).
8. **Never hand-edit a generated artifact** — schema dumps, generated clients,
   lockfiles, built baselines. Regenerate through its tool.
9. **Context is a budget.** Don't re-read a file already read this session
   unless it may have changed, edit surgically rather than rewriting a file
   whole, and send a broad search to a subagent. {#context-economy}
10. **Verify before asserting.** Never state an API name, flag, version, commit
    SHA, package name, path, or a library's *behaviour* from memory — trained
    memory is a snapshot of a release this project does not pin. Read the
    installed code or its docs; where you cannot verify, say so. Scoped forms
    bind a blocking review finding (`agentic-workflow:cross-review-reviewer`)
    and a recalled memory (`agentic-workflow:memory-policy`).
    {#verify-before-asserting}

## Code style philosophy {#code-style}

The toolchain is opinionated — defer to it; gate commands are stack-specific
(e.g. `rails.md#gates`). Regardless of stack:

- **Never silence.** Fix the code; never disable a linter rule, append to a todo
  file, or add an ignore comment. Where a rule is genuinely wrong for a case,
  say so and open a plan.
- **Comments: none by default.** Add one only where the *why* is non-obvious;
  never narrate the *what*.
- **Durable surfaces are written in plain prose** — commits, pull request titles
  and bodies, code comments, Linear issues, Notion pages — in ordinary
  sentences, whatever compressed style the chat is using. The rule lives here
  and is cited, never restated, elsewhere.
  (`agentic-workflow:durable-surface-prose`)
- **Run every gate before reporting done**, iterating to green rather than
  reporting a partial pass, and never report done on a gate you did not run.
  Which commands make up the suite is stack-specific (e.g. `rails.md#gates`).
  (`agentic-workflow:gates`)
- **Run each gate as its own unpiped command.** A pipe (`… | tail -1`) reports
  its last stage, so a failure reads as green, and `&&` does not rescue it.
  (`agentic-workflow:gates`)
## Silent execution {#silent-execution}

Do the work; don't perform it. The deliverable is what the turn produces; the
tool transcript records how.

- **Never narrate a step or your thought process** — no announcing the next
  step, naming a tool, or recapping the one that ran.
- **Never explain a routine action** (reading a file, running the gates, cutting
  a branch, pushing) unless the human asks or something went wrong.
- **No progress commentary, no filler, no jokes, no emoji.**
- **Speak unprompted only for** an error you cannot resolve, a question that
  genuinely blocks the work, or a confirmation or disclosure
  [Boundaries](#boundaries) requires — that section owns the list, including the
  staging-deploy disclosure.
- **Say it the way the final report is said** — result first, no preamble, no
  sign-off ([Reporting](#reporting)).
- **Never suppress a human gate.** Where a skill mandates a stop for a human —
  the review-loop approval ([Review-driven changes](#review-driven-changes)),
  the board-hygiene sweep confirmations, the flagged-todo list confirmation —
  that stop and what the human needs to answer it are the step's deliverable.

## Reporting to the human {#reporting}

This governs the **final report**, the message that closes a task; everything
before it belongs to [Silent execution](#silent-execution), whose permitted
utterances take the shape below.

- **No preamble, no restatement, no sign-off.**
- **Lead with the result** — the finding, the failure, the `file:line` — with
  reasoning after it and only where it is not obvious. Quote a failing gate by
  its shortest decisive line rather than pasting the log.
- **The report is complete.** Name a skipped step as skipped, a check not run as
  not run, a failure as a failure; dropping the caveat is a different claim, not
  concision. This governs the closing message only, and never licenses narration
  on the way there.
- **It covers the live exchange only** — durable surfaces keep full plain prose
  ([Code style](#code-style)).

## Testing {#testing}

- **Every behaviour change ships with a test.** A failing test is a blocker: fix
  the test or the code — never comment it out, never skip or ignore it without a
  linked plan or ticket.
- **Don't mock what you don't own.** Wrap a third-party call behind your own
  adapter and mock the adapter.
- **Flaky tests get fixed, not re-rolled.** A test failing on a clean diff is
  root-caused and fixed in its own pull request with a linked ticket, never
  merged on a bare rerun-to-green and never silently quarantined (`xit` or skip
  only with a linked fix ticket). (`agentic-workflow:pr-ci-watch`)

Stack-specific testing rules live in your stack baseline (e.g.
`rails.md#testing-rails`).
## Workflow {#workflow}

- **Work in your own worktree, in every repository, always** — never edit,
  branch, or commit in a shared clone, including a sibling repo you reach into.
  Create it before the first edit, confirm your branch before every commit, and
  drive create and teardown through the project's `worktree` tooling
  ([#worktrees]).
- Branch `ai/<type>/<slug>` (e.g. `ai/feat/class-schedule`); never push to a
  protected branch.
- **Conventional Commits**: `type(scope): subject`, imperative, ≤72-char
  subject; the body explains *why*.
- **Every change ships as a pull request**, never a direct commit to a protected
  branch, titled `[<KEY>-NN][<tag>] <imperative summary>` — `<KEY>` is the
  repo's Linear team key (`SQH` in squarehour, `MOV` in movely), `<tag>` mirrors
  the commit type. Fill the applicable template, keep its `Closes: <KEY>-NN`
  line, screenshot any user-visible change, and get CI green before review.
  (`agentic-workflow:pr-cadence`, `agentic-workflow:pr-template`)
- **Track work in Linear**, not GitHub issues, citing `<KEY>-NN` in the pull
  request. (`agentic-workflow:linear-update`)
- **Claim a ticket before the first edit by flipping it to In Progress** — the
  lock other sessions read. Pick another if it is already In Progress elsewhere.
  Flip it once at pickup; the GitHub integration owns later transitions.
  (`agentic-workflow:linear-update`)
- **Watch CI after opening the pull request**, having confirmed the branch is
  rebased on its base. Fix a red check; never re-roll or force it through.
  (`agentic-workflow:pr-ci-watch`)
- **Clean up after every merge**, in every repository the task touched — base
  branch fast-forwarded, merged branch deleted, worktree torn down. A base
  checked out in another worktree is the exception and needs nothing.
  (`agentic-workflow:pr-ci-watch`)
- **Compare against a freshly fetched `origin/main`, never a local ref** — run
  `git fetch origin` before diffing against main, judging whether a change
  landed, or reading another repo's state ([#verify-before-asserting]).
- **Worktrees and the run lifecycle** — drive both with the project's own
  commands, read rather than recalled ([#verify-before-asserting]):
  `bin/worktree` for parallel checkouts, never hand-rolled
  `git worktree add/remove`; `mise run start`, `mise run stop`, `mise run reset`
  for the app. Each checkout carries its own port, database namespace, and
  services, so never infer the server, hand-start a dev process (`rails s`,
  `bin/dev`, …), or hardcode a port. (`rails-stack:worktree`) {#worktrees}
- **Worktree and main pre-flight** — at pickup verify the branch is fresh off
  `origin/main` rather than carrying another ticket's commits, and verify which
  database the shell targets before running `rails` or `rspec`, since the agent
  shell loads neither mise nor `.env`. (`rails-stack:worktree`)
  {#worktree-preflight}
- **A ticket is finished when its pull request is open, not when the code is
  green.** Run the arc through in one pass — claim, implement, gates, commit,
  push, open the pull request, watch CI — and report the result rather than
  pausing at working code to ask whether to open it. Stop only where continuing
  would be wrong: the human scoped the request narrowly, the gates are red in a
  way that needs their decision, the ticket is blocked or ambiguous, or the work
  needs a plan. Uncertainty about whether the change is *right* resolves to a
  draft pull request. (`agentic-workflow:ticket-to-pr`)
- **A stack is reviewed at every rung, and the last rung discloses what it
  carries.** Branch protection guards the default branch only, so a pull request
  based on another feature branch merges with no required review. Point the
  review at *every* pull request in the stack, and have the final one list the
  stacked pull requests merged into its branch and what each lands.
  (`agentic-workflow:pr-cadence`)
## Boundaries — ask before acting {#boundaries}

The agent **must pause and confirm** before:

- Destructive Git ops: `reset --hard`, `push --force`, branch delete,
  `clean -fd`, `checkout .`.
- Schema-touching migrations on existing tables (rename, drop, `NOT NULL` add
  without default).
- Editing secrets or deploy config (credential stores, key material,
  environment files, deploy manifests).
- Adding, removing, or major-bumping a dependency.
- Anything that talks to a remote system: `git push`, opening a pull request on
  someone's behalf, deploys, third-party API writes, Slack or Linear posts. Two
  exceptions are pre-authorized — a routine Linear update, meaning a status flip
  and a comment on the ticket you are actively working and never a project,
  milestone, or initiative change (`agentic-workflow:linear-update`), and a
  **staging** deploy on the terms below.
- Disabling a test or a linter or security finding.

The agent **must never**, regardless of permission:

- Run a **production** deploy command. A **staging** deploy is instead
  pre-authorized, on disclosure rather than permission: say you are deploying
  staging before running the command, and report what happened. Treat a deploy
  as production whenever it would touch a production destination, whatever it is
  named; where you cannot tell, it is production and you stop.
- Force-push to a protected branch.
- Merge a pull request with `--admin`, which bypasses branch protection; let it
  merge through its gates. Whether it lands the moment they go green is the
  human's call, so **arm auto-merge only when asked to**.
  (`agentic-workflow:pr-cadence`)
- Commit key material.
- Print, log, or persist a fetched secret, or paste one into a pull request,
  commit, Linear issue, or Notion page. Fetch it at the moment of use and pass
  it into the consuming command via the environment.
  (`agentic-workflow:secrets-access`)
- Use `--no-verify`, `--no-gpg-sign`, or otherwise bypass the commit hooks or
  the signature: every commit lands gpg-signed and verifiable. Where commits are
  not signing, fix the gpg-agent rather than committing unsigned.
- Create a commit or file content **server-side** — the GitHub API contents or
  git-data endpoints, or a `createCommitOnBranch` mutation. Clone, branch, edit,
  and `git commit` locally. The one carve-out, the unattended baseline-sync bot
  in `propitech/claude-plugins`, is **not yours to invoke**.
  (`agentic-workflow:signed-commits`)
- **Approve your own pull request from a second identity you operate.** An
  approval GitHub counts comes from a separate reviewer session the human
  launched, never from the authoring session fetching the reviewer credential. A
  session whose own pull request is blocked on review leaves it blocked and says
  so; a reviewer-launch helper that rejects your arguments is this rule firing.
  (`agentic-workflow:cross-review-reviewer`) {#review-identity}
- **Write a session URL onto a durable surface.** No `claude.ai/code/session_…`
  link, and no `Claude-Session:` trailer carrying one, in a commit message, a
  pull request title or body, a review or issue comment, a Linear issue, a
  Notion page, or code. Where the harness's default commit instruction says to
  append that trailer, drop it and keep `Co-Authored-By:`; this rule overrides
  the harness default. (`agentic-workflow:durable-surface-prose`)
  {#no-session-urls}
## Plans (Linear) {#plans}

- The plan or epic lives in **Linear** (Propitech workspace), not the repo: an
  epic is a **project** carrying **Goal**, **Deliverables**, **Sequencing**,
  **Out of scope**, and **Open questions**, broken into one-PR **issues**.
  (`agentic-workflow:plan-first`, `agentic-workflow:decompose-deliverables`)
- **Flagged "Out of scope" and "Deferred" items become Backlog issues.**
  (`agentic-workflow:flagged-todo`)
- **The team encodes the product; a `Scope` label marks only the exceptions.** An
  unlabelled issue belongs to its team's primary product; label only work that
  is not (`Tooling`, `Shared`, or a per-repo scope). Add `Type` and `Discipline`
  when known.
- **A project enters Current only when a human commits to it**, after a board
  sweep and with WIP sized to measured velocity. No code begins until the
  project is Current and the ticket sits in the current cycle at Todo.
  (`agentic-workflow:board-hygiene`)
- **Archiving is a GraphQL job** with a key read from 1Password: the Linear MCP
  cannot archive, and archiving is what frees the workspace issue cap.
  (`agentic-workflow:linear-archive`)
- Update the plan as the work evolves. A stale plan is worse than no plan.

## Documentation {#documentation}

Knowledge that lives only in a chat session is knowledge the next person does
not have. Write it down where it will be found:

- **The repository is the source of truth for how to build the thing** — stack,
  layering, gates, run lifecycle, conventions — reachable from its README. A
  rule holding across Propitech projects goes into the shared baseline, never
  copied into each repo.
- **Notion is the source of truth for the product and the durable decisions**,
  and a shipped feature is written up there.
  (`agentic-workflow:document-feature`)
- **Claude Design is the source of truth for the design**, in every repository
  and at every stage of a product's life. The repository implements the
  direction and never becomes it, so where code and canvases disagree the
  canvases are right. Harvest direction only — never ship an HTML export.
  (`agentic-workflow:design-canvas`, `agentic-workflow:tool-interfaces`)
- **A material decision is recorded when it is made, not remembered**, and what
  is recorded is the *why*. (`agentic-workflow:document-decision`)
- **Documentation ships with the change**, in the pull request that changes the
  behaviour.
- **A stale document is worse than a missing one**, because it is believed: fix
  it or delete it.
## Review-driven changes {#review-driven-changes}

When the human is walking the agent through pull request review feedback
(`agentic-workflow:review-loop`):

1. **One comment per prompt** — no batching, no cleanup of nearby code.
2. **Challenge before applying.** Where the feedback is wrong, incomplete, or
   contradicts house rules, push back with reasoning before touching code.
3. **Fix, don't silence** — never bypass a finding with an ignore directive
   ([Never silence](#code-style)).
4. **Run the gates every iteration**, plus the relevant test subset, before
   reporting back.
5. **Wait for "satisfied" before committing.** Show the diff and gate results,
   then stop. Commit only on explicit approval — one commit per review comment
   unless told otherwise.
## Agent instructions (this file) {#agent-instructions}

This `AGENTS.md` is a **generated** artifact — a pinned baseline plus this
project's deltas — treated like any other generated file
([Operating principles](#operating-principles)).

- **Don't hand-edit the managed region** or the vendored
  `.config/propitech/agents/<layer>.md` caches: they are checksum-pinned, so a
  hand-edit fails the local re-render check.
- **Project-specific rules go in `.config/propitech/agents/deltas.md`**, the
  only hand-authored agent surface here. Regenerate with `bin/agents-render`,
  then commit `AGENTS.md` alongside.
- **A machine-local `AGENTS.md.local` is read when present** and wins on
  conflict. It never lands in git, so shared rules belong in `deltas.md` or
  upstream.
- **Newer baselines arrive as sync pull requests** from the upstream currency
  workflow (`agents-currency.yml`, driving `bin/agents-sync-consumer`); review
  one like a dependency bump. Local `bin/agents-render` only re-renders the
  pinned version.
- **Change a shared rule upstream** in `propitech/claude-plugins`, where the
  fragment is the single source.
- **Agent memory keeps only machine-local, non-shareable facts.** Anything
  shareable belongs in its owning home (a claude-plugins skill or fragment, this
  repo's docs or deltas, or Notion); before saving one, alert the user and
  propose that home. (`agentic-workflow:memory-policy`)

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

On top of [base.md#workflow] (which already mandates the `ai/<type>/<slug>`
branch name and tracking work in Linear):

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
