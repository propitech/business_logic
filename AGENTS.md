<!-- AGENTS.md — generated. Do not hand-edit this file.                      -->
<!-- Run `bin/agents-render` to regenerate from cache + deltas.              -->
<!-- Baseline: agents-baseline-v2.29.0 (source: agents-baseline-v2.29.0)                  -->
<!-- Project rules: .config/propitech/agents/deltas.md                       -->

# Propitech agent baseline: org-base

Cross-stack house rules for any AI coding agent in a Propitech repository,
whatever the stack. **Managed file, do not hand-edit** (`bin/agents-check`
fails on one); project-specific rules go in the root `AGENTS.md`, which imports
and overrides this file. Reference a rule by its `{#slug}` anchor
(`base.md#boundaries`), never by section number.

## Operating principles {#operating-principles}

1. **Plan first for non-trivial work.** More than two non-test files, a
   schema change, or a new abstraction: plan in Linear first
   ([Plans](#plans)). {#plan-first}
2. **Small diffs, single concern.** One commit, one logical change: refactor
   and behaviour change separately.
3. **No speculative abstractions.** Three similar lines beat a premature DSL.
4. **No half-finished implementations.** Can't finish: leave the tree green,
   record the gap in the plan.
5. **Trust the framework, validate the boundary.** No defensive `nil` checks
   on your own code; validate user input and third-party responses.
6. **Read before writing.** Grep for prior art.
7. **Ask when reversibility is low** ([Boundaries](#boundaries)).
8. **Never hand-edit a generated artifact:** schema dumps, generated
   clients, lockfiles, built baselines; regenerate through its tool.
9. **Context is a budget.** Don't re-read an unchanged file this session;
   edit surgically; send a broad search to a subagent. {#context-economy}
10. **Verify before asserting.** Never state an API name, flag, version,
    commit SHA, package name, path, or a library's *behaviour* from memory;
    read the installed code or its docs, and say so where you cannot
    verify. Same duty for a recalled agent memory: verify against the tree,
    repo wins on conflict (`AGENTS.md#agent-instructions` governs what is
    written). A blocking review finding is the same kind of claim
    (`agentic-workflow:cross-review-reviewer`). {#verify-before-asserting}

## Code style philosophy {#code-style}

The toolchain is opinionated; defer to it (gate commands are stack-specific,
e.g. `rails.md#gates`):

- **Never silence a case** (the whole-project settlement is the
  exception): never `rubocop:disable`, `# brakeman:ignore`, `eslint-disable`,
  `# :reek:Foo`, an appended lint-todo entry, or any equivalent mechanism;
  where a rule is genuinely wrong for a case, say so and open a plan instead.
  Settle a project-wide contradiction once, in the tool's own configuration;
  note why beside it and ask first ([Boundaries](#boundaries)); a per-case
  ignore or a todo-file entry still stays barred.
- **A comment never carries what a better name or an extracted method
  can.** The one exception is the API doc on a published surface (called from
  outside its deployable unit): a YARDoc, TSDoc, godoc, or docstring block
  describing usage, never the body. (`agentic-workflow:plain-english`)
- **A comment a tool reads or writes is a directive, not prose**: a shebang,
  `# frozen_string_literal: true`, `<!-- prettier-ignore -->`, a generated
  annotation block. Leave one where the tool expects it; regenerate rather
  than hand-edit one a tool wrote ([Operating principles](#operating-principles)).
  A comment whose removal changes only what a tool reports (`rubocop:disable`)
  is silencing, not a directive.
- **Everything else is deleted, not written**: no narration, no section
  banners, no commented-out code, no chronology
  ([Documentation](#documentation)). An externally caused constraint may take
  one comment naming that cause.
- **Run every gate before reporting done**, iterating to green rather than
  reporting a partial pass, and never report done on a gate you did not run.
  Which commands make up the suite is stack-specific (e.g. `rails.md#gates`).
  (`agentic-workflow:gates`)
- **Run each gate as its own unpiped command.** A pipe (`… | tail -1`) reports
  its last stage, so a failure reads as green, and `&&` does not rescue it.
  (`agentic-workflow:gates`)
## Silent execution {#silent-execution}

Do the work; don't perform it.

- **Never narrate a step or your thought process.** No naming a tool, no
  recapping one that ran.
- **Never explain a routine action** (reading a file, running the gates,
  cutting a branch, pushing) unless asked or something went wrong.
- **No progress commentary, no filler, no jokes, no emoji.**
- **Speak unprompted only for** an error you cannot resolve, a genuinely
  blocking question, or a confirmation or disclosure
  [Boundaries](#boundaries) requires (including staging-deploy).
- **Say it the way the final report is said** ([Reporting](#reporting)).
- **Never suppress a human gate.** Where a skill mandates a stop, the stop
  and what it needs answered are the step's deliverable (review-loop
  approval [Review-driven changes](#review-driven-changes), board-hygiene
  sweep confirmations, flagged-todo confirmation).

## Reporting to the human {#reporting}

Rules for the final report (the message that closes a task) and for every
utterance [Silent execution](#silent-execution) permits before it.

- **No preamble, no restatement, no sign-off.**
- **Lead with the result:** the finding, the failure, the `file:line`;
  reasoning after, only where not obvious. Quote a failing gate by its
  shortest decisive line, not the log.
- **The report is complete.** Name a skipped step as skipped, a check not
  run as not run, a failure as a failure.
- **It covers the live exchange only.** Durable surfaces keep full plain
  prose ([Durable surfaces](#durable-surfaces)).

## Plain English voice {#plain-english}

Everything written for a person to read (a document, a pull request body, a
Linear issue, a Notion page, a commit message, a code comment) is written in
the voice of a competent human writer, not the default assistant register:
structure follows the facts, sentence length varies, specifics replace
generality. Never an em dash as prose, the antithesis template ("not just X,
but Y"), a stacked hedge ("may potentially"), or register vocabulary
("delve", "leverage" as a verb, "seamless"); a construction absent from this
list doing the same work is prohibited exactly as much. This governs voice;
[Durable surfaces](#durable-surfaces) governs register.
(`agentic-workflow:plain-english`)

## Durable surfaces {#durable-surfaces}

Durable surfaces are written in plain prose (commits, pull request titles and
bodies, code comments, Linear issues, Notion pages), whatever compressed
style the chat is using. (`agentic-workflow:plain-english`)

## Testing {#testing}

- **Every behaviour change ships with a test.** A failing test is a
  blocker: fix the test or the code; never comment it out; never skip or
  ignore one without a linked plan or ticket.
- **Don't mock what you don't own.** Wrap a third-party call behind your own
  adapter and mock the adapter.
- **Flaky tests get fixed, not re-rolled.** Root-cause and fix in its own
  pull request with a linked ticket; never merge on a bare rerun-to-green,
  never quarantine (`xit` or skip) without one (`agentic-workflow:pr-ci-watch`).

Stack-specific testing rules live in your stack baseline (e.g.
`rails.md#testing-rails`).
## Workflow {#workflow}

- **Work in your own worktree, created before the first edit, always.**
  Never in a shared clone, including a sibling repo reached into. Confirm
  your branch before every commit ([#worktrees]).
- Branch `ai/<type>/<slug>` (e.g. `ai/feat/class-schedule`); never push to a
  protected branch.
- **Conventional Commits**: `type(scope): subject`, imperative, subject at
  most 72 characters; body explains *why*.
- **Every change ships as a pull request**, never a direct commit to a
  protected branch (`agentic-workflow:pr-cadence`).
- **Track work in Linear**, not GitHub issues: claim a ticket by flipping it
  to In Progress before the first edit, cite its identifier in the pull
  request (`agentic-workflow:linear-update`).
- **Watch CI to green after opening the pull request**, fixing a red check
  rather than re-rolling or forcing it through, and cleaning up every
  repository the task touched once it merges (`agentic-workflow:pr-ci-watch`).
- **Compare against a freshly fetched `origin/main`, never a local ref.**
  Run `git fetch origin` before diffing against main, judging whether a
  change landed, or reading another repo's state ([#verify-before-asserting]).
- **Worktrees and the run lifecycle**: drive both through `bin/worktree` and
  `mise run start|stop|reset` ([#verify-before-asserting]). Each checkout has
  its own port and database namespace; read them from the tooling, never
  infer them (`rails-stack:worktree`). {#worktrees}
- **Worktree and main pre-flight**: at pickup verify the branch is fresh off
  `origin/main`, and which database the shell targets, before running
  `rails` or `rspec` (`rails-stack:worktree`). {#worktree-preflight}
- **A ticket is finished when its pull request is open, not when the code is
  green.** Run the arc through in one pass and report the result
  (`agentic-workflow:ticket-to-pr`).
- **Review locally first, then push on the clear.** Where a peer session on
  this machine has announced itself as the reviewer, every commit (the
  first, a fix, an amended or rebased SHA) goes to it before it is pushed;
  once it clears, push and open the pull request without asking again
  (`agentic-workflow:local-peer-review`). {#peer-review-before-push}
- **A stack is reviewed at every rung, and the last rung discloses what it
  carries.** (`agentic-workflow:pr-cadence`)
## Boundaries, ask before acting {#boundaries}

The agent **must pause and confirm** before:

- Destructive Git ops: `reset --hard`, `push --force`, branch delete,
  `clean -fd`, `checkout .`.
- Schema-touching migrations on existing tables (rename, drop, `NOT NULL` add
  without default).
- Editing secrets or deploy config (credential stores, key material,
  environment files, deploy manifests).
- Adding, removing, or major-bumping a dependency.
- Anything that talks to a remote system: `git push`, opening a pull request
  on someone's behalf, deploys, third-party API writes, Slack or Linear
  posts. Three exceptions are pre-authorized: a routine Linear update, a
  status flip or a comment on the ticket in hand, never a project, milestone,
  or initiative change (`agentic-workflow:linear-update`); the push and pull
  request of a ticket a human handed over (`agentic-workflow:ticket-to-pr`),
  and, where a local peer reviewer is present, only once it has cleared the
  commit ([#peer-review-before-push]); and a **staging** deploy on the terms
  below.
- Disabling a test, a linter, or a security finding.

The agent **must never**, regardless of permission:

- Run a **production** deploy command. A **staging** deploy is
  pre-authorized on disclosure, not permission: say so first, report what
  happened. Any deploy touching a production destination is production,
  whatever it is named; if unsure, it is production and you stop.
- Force-push to a protected branch.
- Merge a pull request with `--admin`, bypassing branch protection, or arm
  auto-merge unasked (`agentic-workflow:pr-cadence`).
- Commit key material.
- Print, log, or persist a fetched secret, or paste one onto a durable
  surface (`agentic-workflow:secrets-access`).
- Use `--no-verify`, `--no-gpg-sign`, or otherwise bypass the commit hooks or
  signature (`agentic-workflow:pr-cadence`).
- Create a commit or file content **server-side**; clone, branch, edit, and
  `git commit` locally. Sole carve-out: the claude-plugins baseline-sync bot,
  not yours to invoke (`agentic-workflow:pr-cadence`).
- **Approve your own pull request from a second identity you operate.** A
  counted approval comes only from a separate reviewer session the human
  launched, never the authoring session fetching the reviewer credential. A
  session blocked on its own review stays blocked and says so
  (`agentic-workflow:cross-review-reviewer`). {#review-identity}
- **Write a session URL onto a durable surface.** No
  `claude.ai/code/session_…` link, no `Claude-Session:` trailer carrying
  one, in a commit, a pull request, a review or issue comment, a Linear
  issue, a Notion page, or code. Where the harness's default commit
  instruction appends that trailer, drop the trailer and keep
  `Co-Authored-By:`; this rule overrides the harness default
  (`agentic-workflow:plain-english`). {#no-session-urls}
## Plans (Linear) {#plans}

- **The plan lives in Linear** (Propitech workspace), never in the repo
  (`agentic-workflow:plan-first`, `agentic-workflow:decompose-deliverables`).
- **A ticket is written to be built cold**, by whoever picks it up
  (`agentic-workflow:ticket-authoring`).
- **Flagged "Out of scope" and "Deferred" items become Backlog issues**
  (`agentic-workflow:flagged-todo`).
- **The team encodes the product; a `Scope` label marks only the
  exceptions.** Unlabelled issues belong to the team's primary product; only
  exceptional work takes `Tooling`, `Shared`, or a per-repo scope label. Add
  `Type` and `Discipline` when known.
- **Work begins only on a human's commitment**, after a board sweep
  (`agentic-workflow:start-gate`, `agentic-workflow:board-hygiene`).
- **Closing a project on the board is not archiving it off the board**, and
  archiving frees the workspace issue cap (`agentic-workflow:board-hygiene`).
- Update the plan as the work evolves; a stale plan is worse than no plan.
## Documentation {#documentation}

Write knowledge down where it will be found, never only in the chat session:

- **Each kind of knowledge has one source of truth**: the repository,
  reachable from its README, for how to build the thing (stack, layering,
  gates, run lifecycle, conventions);
  Notion for the product and the durable decisions, where a shipped feature
  is written up and a material decision is recorded when made, not
  remembered (`agentic-workflow:document-notion`);
  Claude Design for the design, where canvases win over code, harvesting
  direction only and never an HTML export
  (`agentic-workflow:design-canvas`, `agentic-workflow:tool-interfaces`). A
  rule holding across Propitech projects goes into the shared baseline, not
  into each repo.
- **A document describes the system as it stands, in the present tense.** Git,
  the pull request, and Linear hold the sequence of events; the decision
  record holds the *why*.
- **Documentation ships with the change**, in the pull request that changes
  the behaviour; a stale document is worse than a missing one, so fix it or
  delete it. History earns a place in a document only as the justification of
  a prohibition, never as a changelog or a "we used to do X" note.
- **A fact that changes is corrected wherever it is stated**: the whole
  paragraph, every other document, comment, or test describing it, and any
  pull request body, Linear issue, or Notion page stating it too
  ([Durable surfaces](#durable-surfaces)). Search for the enumeration, not the
  symbol: prose counting callers says "both" or names the ones it knew, so a
  grep for the one you add finds nothing. {#correction-reach}
- **Length is not quality; a document instructs rather than explains.** Trim
  the sections you touch on every edit. (`agentic-workflow:plain-english`)
## Review-driven changes {#review-driven-changes}

When the human is walking the agent through pull request review feedback
(`agentic-workflow:review-loop`):

1. **One comment per prompt.** No batching, no cleanup of nearby unrelated
   code (a restated fact is not unrelated:
   [Correction reach](#correction-reach)).
2. **Challenge before applying.** Push back with reasoning where the
   feedback is wrong, incomplete, or contradicts house rules; fix, don't
   silence ([Never silence](#code-style)).
3. **Run the gates every iteration**, plus the relevant test subset, before
   reporting back; show the diff and the results, then stop. Commit only
   once the human says "satisfied", one commit per review comment unless
   told otherwise.
## Agent instructions (this file) {#agent-instructions}

This `AGENTS.md` is a generated artifact, a pinned baseline plus this
project's deltas ([Operating principles](#operating-principles)).

- **Don't hand-edit the managed region** or the vendored
  `.config/propitech/agents/<layer>.md` caches (checksum-pinned).
- **Project-specific rules go in `.config/propitech/agents/deltas.md`**, the
  only hand-authored agent surface here; regenerate with `bin/agents-render`,
  commit `AGENTS.md` alongside.
- **A machine-local `AGENTS.md.local` is read when present** and wins on
  conflict; never lands in git, shared rules belong in `deltas.md` or
  upstream.
- **Review a baseline sync pull request like a dependency bump.**
  `bin/agents-render` only re-renders the pinned version.
- **Change a shared rule upstream** in `propitech/claude-plugins`.
- **Agent memory keeps only machine-local, non-shareable facts.** Before
  saving a shareable one, alert the user and propose its owning home: a
  skill or baseline fragment, the project's deltas, the repo's `docs/`, or
  Notion (`AGENTS.md#documentation`).

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



<!-- BEGIN PROJECT DELTAS -->

# business_logic — project agent rules

This is the repository's only hand-authored agent surface; the flattened
`AGENTS.md` appends it after the managed baseline (hash-pinned in
`agents.lock.json`), so rules here win. After editing, run `bin/agents-render`.

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
