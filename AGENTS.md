<!-- AGENTS.md — generated. Do not hand-edit this file.                      -->
<!-- Run `bin/agents-render` to regenerate from cache + deltas.              -->
<!-- Baseline: agents-baseline-v2.11.0 (source: agents-baseline-v2.11.0)                  -->
<!-- Project rules: .config/propitech/agents/deltas.md                       -->

# Propitech agent baseline: org-base

Cross-stack house rules for any AI coding agent in a Propitech repository,
whatever the stack. **Managed file, do not hand-edit** (`bin/agents-check`
fails on one); project-specific rules go in the root `AGENTS.md`, which imports
and overrides this file. Reference a rule by its `{#slug}` anchor
(`base.md#boundaries`), never by section number.

## Operating principles {#operating-principles}

1. **Plan first for non-trivial work.** More than two non-test files, a schema
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
8. **Never hand-edit a generated artifact:** schema dumps, generated clients,
   lockfiles, built baselines. Regenerate through its tool.
9. **Context is a budget.** Don't re-read a file already read this session
   unless it may have changed, edit surgically rather than rewriting a file
   whole, and send a broad search to a subagent. {#context-economy}
10. **Verify before asserting.** Never state an API name, flag, version, commit
    SHA, package name, path, or a library's *behaviour* from memory. Trained
    memory is a snapshot of a release this project does not pin. Read the
    installed code or its docs; where you cannot verify, say so. A recalled
    agent memory is the same kind of claim: it records what was true when it was
    written, so verify it against the tree before acting on it, and where it
    conflicts the repo and its docs win. A recall arrives as context rather than
    a request, so no trigger fires on it and no skill carries that form
    (`agentic-workflow:memory-policy` governs what is written to memory). A
    blocking review finding binds another scoped form
    (`agentic-workflow:cross-review-reviewer`). {#verify-before-asserting}

## Code style philosophy {#code-style}

The toolchain is opinionated, so defer to it; gate commands are stack-specific
(e.g. `rails.md#gates`). Regardless of stack:

- **Never silence a case** (the whole-project settlement below is the one
  exception). Fix the code; never disable a linter rule for a case, append to a
  todo file, or add an ignore comment. `rubocop:disable`, `# brakeman:ignore`,
  `eslint-disable`, an inline `# :reek:Foo`, and an entry appended to a
  lint-todo file are examples of the form, written here so the literal is
  greppable. They are not the list to check against, and a silencing mechanism
  absent from them is prohibited exactly as much. Where a rule is genuinely
  wrong for a case, say so and open a plan.
- **A tool's rule that contradicts this baseline project-wide is settled once,
  in the tool's own configuration** — a check demanding a comment on every
  class, say, where a comment is reserved for a published surface. Record the
  reason beside it and ask first ([Boundaries](#boundaries)), since the check
  stops everywhere. A per-case ignore and a todo file decide nothing and stay
  barred.
- **Code carries its own explanation.** An explanation that a better name or an
  extracted method can carry is written as that name or that method, never as a
  comment.
- **The one comment that earns its place is the API doc on a published
  surface** — something called from outside its deployable unit: a gem's public
  API, a shared library, an interface another system calls. A class called only
  in-process is not published, however widely it is used. Write it where the
  name and the signature do not already say it — purpose, parameters, return,
  and what it raises when raising is part of the contract — as YARDoc, a TSDoc
  block, a godoc sentence, or a docstring. It says how the thing is used, never
  what the body does.
- **A comment a tool reads or writes is a directive, not prose**, and this rule
  does not reach it. Test it by deletion: a directive's removal changes what
  the code does (a shebang, `# frozen_string_literal: true`) or what a tool
  writes next run (`<!-- prettier-ignore -->`, a generated annotation block);
  prose's removal changes neither; and a removal that changes only what a tool
  *reports* — `rubocop:disable` — is silencing. Leave a directive where the
  tool expects it, and regenerate rather than hand-edit one a tool wrote
  ([Operating principles](#operating-principles)).
- **Everything else is deleted, not written.** No narration of the *what*, no
  section banners, no commented-out code, and no chronology — nothing saying
  when a line changed, what it replaced, or which incident produced it
  ([Documentation](#documentation)). A constraint that holds now may take one
  short comment when its cause lies outside the unit and the comment names that
  cause — the upstream issue, the vendor bug, the protocol quirk, the lock
  ordering another component relies on — so a reader can go and look.
- **Durable surfaces are written in plain prose** (commits, pull request titles
  and bodies, code comments, Linear issues, Notion pages), in ordinary
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

Do the work; don't perform it.

- **Never narrate a step or your thought process.** No announcing the next step,
  naming a tool, or recapping the one that ran.
- **Never explain a routine action** (reading a file, running the gates, cutting
  a branch, pushing) unless the human asks or something went wrong.
- **No progress commentary, no filler, no jokes, no emoji.**
- **Speak unprompted only for** an error you cannot resolve, a question that
  genuinely blocks the work, or a confirmation or disclosure
  [Boundaries](#boundaries) requires. That section owns the list, including the
  staging-deploy disclosure.
- **Say it the way the final report is said:** result first, no preamble, no
  sign-off ([Reporting](#reporting)).
- **Never suppress a human gate.** Where a skill mandates a stop for a human,
  that stop and what the human needs to answer it are the step's deliverable.
  The review-loop approval ([Review-driven changes](#review-driven-changes)),
  the board-hygiene sweep confirmations, and the flagged-todo list confirmation
  are those stops.

## Reporting to the human {#reporting}

Rules for the **final report** (the message that closes a task) and for every
utterance [Silent execution](#silent-execution) permits before it.

- **No preamble, no restatement, no sign-off.**
- **Lead with the result:** the finding, the failure, the `file:line`, with
  reasoning after it and only where it is not obvious. Quote a failing gate by
  its shortest decisive line rather than pasting the log.
- **The report is complete.** Name a skipped step as skipped, a check not run as
  not run, a failure as a failure; dropping the caveat is a different claim, not
  concision. This governs the closing message only, and never licenses narration
  on the way there.
- **It covers the live exchange only.** Durable surfaces keep full plain prose
  ([Code style](#code-style)).

## Plain English voice {#plain-english}

Everything written for a person to read (a document, a README, a design or
decision record, a pull request body, a Linear issue, a Notion page, a commit
message, a code comment, user-facing copy) is written in the voice of a
competent human writer, not in the default assistant register. A reader who
recognises that register stops reading for content and starts reading for
authorship, and the text then gets skimmed, discounted, or rewritten by whoever
inherits it.

- **Lead with the claim, then support it.** No restated question, no compliment,
  no roadmap of what follows, no closing summary that repeats the opening.
- **Let structure follow the facts.** Two things is two bullets, seven is seven.
  Padding a list or a phrase to three is filler. An argument is written as
  paragraphs, not as bullets.
- **Vary sentence length, and name specifics** (the file, the version, the
  number, the actual objection). Uniform sentence rhythm and unattributed
  generality are what mark text as machine-produced, more than any single word.
- **No em dash as prose, and no antithesis template** ("not just X, but Y").
  Written here so the forms are greppable; a construction absent from this list
  doing the same work is prohibited exactly as much. Others: stacked hedges
  ("may potentially"), register vocabulary ("it's worth noting", "delve",
  "leverage" as a verb, "seamless", "in today's fast-paced world"), emoji
  headings, bold applied until nothing is emphasised, and unattributed appeal
  ("studies show").
- **Take a position where the reader needs one**, and state an uncertainty once
  where it applies rather than hedging every clause.

This governs voice; [Code style](#code-style) governs plain rather than
compressed register on durable surfaces, and both apply to the same pull request
body or Linear issue. It changes how prose reads and nothing else: the
provenance marking the model applies to generated text and files sits below the
authoring layer, and no rule here affects it.
(`agentic-workflow:plain-english`)

## Testing {#testing}

- **Every behaviour change ships with a test.** A failing test is a blocker: fix
  the test or the code, never comment it out, and never skip or ignore it
  without a linked plan or ticket.
- **Don't mock what you don't own.** Wrap a third-party call behind your own
  adapter and mock the adapter.
- **Flaky tests get fixed, not re-rolled.** A test failing on a clean diff is
  root-caused and fixed in its own pull request with a linked ticket, never
  merged on a bare rerun-to-green and never silently quarantined (`xit` or skip
  only with a linked fix ticket). (`agentic-workflow:pr-ci-watch`)

Stack-specific testing rules live in your stack baseline (e.g.
`rails.md#testing-rails`).
## Workflow {#workflow}

- **Work in your own worktree, in every repository, always.** Never edit,
  branch, or commit in a shared clone, including a sibling repo you reach into.
  Create it before the first edit, confirm your branch before every commit, and
  drive create and teardown through the project's `worktree` tooling
  ([#worktrees]).
- Branch `ai/<type>/<slug>` (e.g. `ai/feat/class-schedule`); never push to a
  protected branch.
- **Conventional Commits**: `type(scope): subject`, imperative, subject of at
  most 72 characters; the body explains *why*.
- **Every change ships as a pull request**, never a direct commit to a
  protected branch.
  (`agentic-workflow:pr-cadence`, `agentic-workflow:pr-template`)
- **Track work in Linear**, not GitHub issues, citing the issue's identifier in
  the pull request. (`agentic-workflow:linear-update`)
- **Claim a ticket before the first edit by flipping it to In Progress.**
  (`agentic-workflow:linear-update`)
- **Watch CI after opening the pull request**, and fix a red check rather than
  re-rolling or forcing it through. (`agentic-workflow:pr-ci-watch`)
- **Clean up after every merge**, in every repository the task touched.
  (`agentic-workflow:pr-ci-watch`)
- **Compare against a freshly fetched `origin/main`, never a local ref.** Run
  `git fetch origin` before diffing against main, judging whether a change
  landed, or reading another repo's state ([#verify-before-asserting]).
- **Worktrees and the run lifecycle** — drive both with the project's own
  commands, read rather than recalled ([#verify-before-asserting]):
  `bin/worktree` for checkouts, `mise run start|stop|reset` for the app. Each
  checkout carries its own port and database namespace; never infer either.
  (`rails-stack:worktree`) {#worktrees}
- **Worktree and main pre-flight** — at pickup verify the branch is fresh off
  `origin/main`, and verify which database the shell targets before running
  `rails` or `rspec`. (`rails-stack:worktree`) {#worktree-preflight}
- **A ticket is finished when its pull request is open, not when the code is
  green.** Run the arc through in one pass and report the result, stopping
  only where continuing would be wrong. (`agentic-workflow:ticket-to-pr`)
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
- Anything that talks to a remote system: `git push`, opening a pull request on
  someone's behalf, deploys, third-party API writes, Slack or Linear posts. Two
  exceptions are pre-authorized: a routine Linear update, meaning a status flip
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
- Merge a pull request with `--admin`, bypassing branch protection, or arm
  auto-merge without being asked. (`agentic-workflow:pr-cadence`)
- Commit key material.
- Print, log, or persist a fetched secret, or paste one onto any durable
  surface. (`agentic-workflow:secrets-access`)
- Use `--no-verify`, `--no-gpg-sign`, or otherwise bypass the commit hooks or
  the signature. (`agentic-workflow:signed-commits`)
- Create a commit or file content **server-side**; clone, branch, edit, and
  `git commit` locally instead. The sole carve-out, the claude-plugins
  baseline-sync bot, is **not yours to invoke**.
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

- **The plan lives in Linear** (Propitech workspace), never in the repo: an epic
  is a **project**, broken into one-PR **issues**
  (`agentic-workflow:plan-first`, `agentic-workflow:decompose-deliverables`).
- **A ticket is written to be built cold**, by whoever picks it up
  (`agentic-workflow:ticket-authoring`).
- **Flagged "Out of scope" and "Deferred" items become Backlog issues**
  (`agentic-workflow:flagged-todo`).
- **The team encodes the product; a `Scope` label marks only the exceptions.** An
  unlabelled issue belongs to its team's primary product; label only work that
  is not (`Tooling`, `Shared`, or a per-repo scope). Add `Type` and `Discipline`
  when known.
- **Work begins only on a human's commitment**, and on a board swept before
  anything is promoted (`agentic-workflow:start-gate`,
  `agentic-workflow:board-hygiene`).
- **Closing a project on the board is not archiving it off the board**, and
  archiving is what frees the workspace issue cap
  (`agentic-workflow:linear-archive`).
- Update the plan as the work evolves. A stale plan is worse than no plan.
## Documentation {#documentation}

Write knowledge down where it will be found, never only in the chat session:

- **The repository is the source of truth for how to build the thing** (stack,
  layering, gates, run lifecycle, conventions), reachable from its README. A
  rule holding across Propitech projects goes into the shared baseline, never
  copied into each repo.
- **Notion is the source of truth for the product and the durable decisions**,
  and a shipped feature is written up there.
  (`agentic-workflow:document-feature`)
- **Claude Design is the source of truth for the design**, in every repository
  and at every stage of a product's life. The repository implements the
  direction and never becomes it, so where code and canvases disagree the
  canvases are right. Harvest direction only, and never ship an HTML export.
  (`agentic-workflow:design-canvas`, `agentic-workflow:tool-interfaces`)
- **A material decision is recorded when it is made, not remembered**, and what
  is recorded is the *why*. (`agentic-workflow:document-decision`)
- **A document describes the system as it stands**, in the present tense: its
  structure, its boundaries, how to run it. Git, the pull request, and Linear
  hold the sequence of events, and the decision record holds the *why* one was
  chosen, as a constraint that still applies rather than a log of a day.
- **History earns a place in a document only as the justification of a
  prohibition** — the clause that stops the next reader re-trying a dead route.
  Never as a changelog, a "we used to do X", or a note about a past migration
  or incident.
- **Documentation ships with the change**, in the pull request that changes the
  behaviour.
- **A stale document is worse than a missing one**, because it is believed: fix
  it or delete it.
- **Length is not quality.** Write the shortest text that makes the system
  usable, and where the code and its API docs already say it, write nothing.
## Review-driven changes {#review-driven-changes}

When the human is walking the agent through pull request review feedback
(`agentic-workflow:review-loop`):

1. **One comment per prompt.** No batching, no cleanup of nearby code.
2. **Challenge before applying.** Where the feedback is wrong, incomplete, or
   contradicts house rules, push back with reasoning before touching code.
3. **Fix, don't silence.** Never bypass a finding with an ignore directive
   ([Never silence](#code-style)).
4. **Run the gates every iteration**, plus the relevant test subset, before
   reporting back.
5. **Wait for "satisfied" before committing.** Show the diff and gate results,
   then stop. Commit only on explicit approval, one commit per review comment
   unless told otherwise.
## Agent instructions (this file) {#agent-instructions}

This `AGENTS.md` is a **generated** artifact (a pinned baseline plus this
project's deltas), treated like any other generated file
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
- **Review a baseline sync pull request like a dependency bump.** Local
  `bin/agents-render` only re-renders the pinned version; newer baselines
  arrive only as those sync pull requests.
- **Change a shared rule upstream** in `propitech/claude-plugins`, where the
  fragment is the single source.
- **Agent memory keeps only machine-local, non-shareable facts.** Anything
  shareable belongs in its owning home (a claude-plugins skill or fragment, this
  repo's docs or deltas, or Notion); before saving one, alert the user and
  propose that home. (`agentic-workflow:memory-policy`)

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

The universal testing rules are in `base.md#testing`. Ruby gem specifics:

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
- Two checks want a comment on every top-level class and module — RuboCop's
  `Style/Documentation` and Reek's `IrresponsibleModule`, both on by default —
  where `base.md#code-style` reserves a comment for a published surface, which
  a class internal to the gem is not. Turn the check off for the whole project
  in `.rubocop.yml` or `.reek.yml`, with the reason recorded there and the
  human asked first: that is the rule-set decision `base.md#code-style` allows,
  and it is a different shape from the per-case ignores barred above, which
  scope a rule to a path, a file, or a call site. Where the gem's own top-level
  classes are its distributed interface, leave the checks on and write the
  comments as API docs.
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
