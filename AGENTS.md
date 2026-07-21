<!-- AGENTS.md — generated. Do not hand-edit this file.                      -->
<!-- Run `bin/agents-render` to regenerate from cache + deltas.              -->
<!-- Baseline: agents-baseline-v1.37.0 (source: agents-baseline-v1.37.0)                  -->
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
- **Durable surfaces are written in plain prose.** Commits, PR titles and
  bodies, code comments, Linear issues, and Notion pages are read by humans
  long after the session ends. Write them in ordinary sentences, whatever
  compressed style the chat is using. No arrow shorthand, no symbol
  abbreviations, no telegraphic fragments.
  (`agentic-workflow:durable-surface-prose`)
- **Run every gate before reporting done.** A green diff is the bar. Iterate the
  suite to green rather than reporting a partial pass, and never report done on
  a gate you did not run. Which commands make up the suite is stack-specific —
  see your stack baseline (e.g. `rails.md#gates`).
  (`agentic-workflow:gates`)
- **Run each gate as its own unpiped command.** A piped gate (`… | tail -1`)
  reports the pipe's last stage, so a failure reads as green — and `&&` does not
  rescue it, because the pipe already turned the failure into a success. Run the
  gate bare and read its own exit status. (`agentic-workflow:gates`)
## Testing {#testing}

- **Every behaviour change ships with a test.** A failing test is a blocker:
  fix the test or the code — never comment it out, never skip or ignore it
  without a linked plan or ticket.
- **Don't mock what you don't own.** Wrap a third-party call behind your own
  adapter and mock the adapter, never the vendor's internals.
- **Flaky tests get fixed, not re-rolled.** A test that fails on a clean diff
  is root-caused and fixed in its own PR with a linked ticket; never merged on a
  bare rerun-to-green, and never silently quarantined (`xit` / skip only with a
  linked fix ticket). (`agentic-workflow:pr-ci-watch`)

Test tooling and stack-specific testing rules live in your stack baseline
(e.g. `rails.md#testing-rails`).
## Workflow {#workflow}

- **Work in your own worktree, in every repository, always.** Never edit,
  branch, or commit in a shared clone — not in the repo you were invoked on, and
  not in a sibling repo you reach across into. Other agent sessions and the
  human are working in the same clones concurrently: a checkout you did not make
  moves `HEAD` under you, and commits you believed were landing on your branch
  land somewhere else. This is not hypothetical and it is not recoverable by
  care — the only fix is isolation. Create the worktree **before the first
  edit**, and confirm which branch you are on before every commit. Create and
  remove worktrees with the `worktree` CLI (`propitech/worktree-tools`,
  installed machine-wide through mise) in **every** repository — `bin/worktree`
  in a Rails repo is a thin binstub over the same tool (see [#worktrees]), and a
  repo that is not a runnable app takes `worktree add <slug> --no-start`. Never
  hand-roll `git worktree add/remove`.
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
- **Claim a ticket before the first edit by flipping it to In Progress.** With
  several agent sessions and humans on one board at once, In Progress is a lock
  the others read: it announces the work is taken, so nobody picks it up twice.
  The reciprocal is binding too — before you start a ticket, check it is not
  already In Progress under another session; if it is, it is claimed, so pick
  another rather than duplicating the work. Flip it once at pickup; the GitHub
  integration owns every later transition. (`agentic-workflow:linear-update`)
- **Watch CI after opening the PR.** Opening it is not landing it. Confirm the
  branch is rebased on its base first — a stale base fails in ways your diff did
  not cause — then watch the checks through and fix what breaks. A red check is
  fixed, never re-rolled and never forced through.
  (`agentic-workflow:pr-ci-watch`)
- **Clean up after every merge.** A merged PR is finished only once the local
  clones reflect it: `git fetch origin --prune`, fast-forward the local base
  branch (`git merge --ff-only` — never a silent hard reset if it diverged),
  delete the merged local branch (`git branch -d`), and tear down the task's
  worktree (with the `worktree` CLI — `bin/worktree rm` in a Rails repo). This
  applies in every repository the task touched. (`agentic-workflow:pr-ci-watch`)
- **Compare against a freshly fetched `origin/main`, never a local ref.** Your
  local `main` and every remote-tracking ref is a snapshot from your last
  fetch; other sessions and humans move the real branch continuously, and a
  sibling clone you reach across into lags further still. Before you diff
  against main, judge whether a change already landed, or read another repo's
  state, run `git fetch origin` (or `git fetch origin main`) first and compare
  against `origin/main`. A conclusion drawn from a stale local ref is wrong
  exactly when it matters most — right after someone else merged.
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
- **Worktree/main pre-flight** — at task pickup verify the worktree's ambient
  state before coding: `git fetch origin main` then `git log origin/main..HEAD`
  (a reused or freshly-added branch can sit on another ticket's commits and leak
  them into the PR — branch fresh off `origin/main` to fix), and confirm the
  database the shell targets. The agent shell does not load mise/`.env`, so
  `WORKTREE_DB_SUFFIX` is empty and `rails`/`rspec` hit the shared
  `*_development` DB — where other worktrees' unmerged migrations leak into your
  `schema.rb` dump. Prefix commands with `WORKTREE_DB_SUFFIX=_sN` (from `.env`),
  and always `git diff origin/main -- db/schema.rb` before committing.
  (`rails-stack:worktree`) {#worktree-preflight}
- **A stack is reviewed at every rung, and the last rung discloses what it
  carries.** Branch protection guards the default branch and nothing else, so a
  pull request whose base is another feature branch merges with no required
  review at all — for stacked work the review gate is not weaker, it is absent,
  and it is absent for the diff least likely to be described accurately, because
  the final pull request's body is written about its own commits rather than
  about everything its branch carries. Both halves are required: point the
  review at *every* pull request in the stack, not only the one targeting the
  default branch; and have the final pull request list the stacked pull requests
  merged into its branch and what each one lands, so the approver judges the
  scope the branch actually carries. (`agentic-workflow:pr-cadence`)
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
  Routine Linear updates — a status flip plus a comment on the ticket you are
  actively working — are the pre-authorized exception; project, milestone, and
  initiative changes are not. (`agentic-workflow:linear-update`) A **staging**
  deploy is pre-authorized too, on the terms set out in the never-list below.
- Disabling a test or a linter/security finding.

The agent **must never**, regardless of permission:

- Run a **production** deploy command. This one names its environment on
  purpose, because it has a carve-out that a production deploy never gets: a
  **staging** deploy is standing pre-authorized, and you may run it without
  asking first. Staging exists to be broken, and an agent that cannot deploy
  staging cannot verify its own work end to end — which is most of the value of
  it having built the change. The condition is disclosure, not permission:
  say that you are deploying staging before you run the command, and report
  what happened afterwards, so the session carries a record of every deploy
  the agent ran. Treat a deploy as production whenever it would touch a
  production destination, whatever the destination is named or the flag says;
  when you cannot tell which environment a command targets, it is production
  and you stop.
- Force-push to a protected branch.
- Merge a PR with `--admin`. It bypasses branch protection — required
  reviews and status checks — to force the change onto the base branch.
  Let the PR merge through its gates: enable auto-merge with
  `gh pr merge --auto --merge` (never `--auto --squash`) so GitHub lands the
  PR itself once every gate passes — a merge commit preserves each commit's own
  gpg signature on the base branch, whereas a squash re-authors the change
  server-side and lands it unsigned, the same bypass the signing rule below
  forbids. Enabling auto-merge is the default final step of opening a PR, not an
  option. (`agentic-workflow:pr-cadence`)
- Commit key material.
- Print, log, or persist a fetched secret, or paste one into a PR, commit,
  Linear issue, or Notion page. Fetch secrets from 1Password at the moment of
  use and pass them straight into the consuming command via the environment.
  (`agentic-workflow:secrets-access`)
- Use `--no-verify`, `--no-gpg-sign`, or otherwise bypass the commit hooks or
  the signature. Every commit must land gpg-signed and verifiable; if commits
  are not signing, fix the gpg-agent rather than committing unsigned.
- Create a commit or file content **server-side** — through the GitHub API
  (contents or git-data endpoints) or a `createCommitOnBranch` GraphQL
  mutation. Server-side commits bypass your local signing key. Clone, branch,
  edit, and `git commit` locally so the gpg-agent signs it.

  This rule has exactly one carve-out, and it is **not yours to invoke**: an
  unattended CI pipeline has no gpg-agent and no key material, so the
  baseline-sync bot in `propitech/claude-plugins` uses `createCommitOnBranch`,
  which GitHub signs with its own web-flow key — a verified commit, not a
  bypass. That carve-out is named here, in the boundary itself, rather than
  left to a skill to disclose, because a never-rule with an undocumented
  exception teaches you that the never-list is negotiable. It is not. If you
  are reading this, you have a gpg-agent: commit locally.
  (`agentic-workflow:signed-commits`)

## Plans (Linear) {#plans}

- The plan/epic lives in **Linear** (Propitech workspace), not the repo: an
  epic is a **project** carrying **Goal**, **Deliverables**, **Sequencing**,
  **Out of scope**, **Open questions** in its description + attached
  documents, broken into one-PR **issues**.
  (`agentic-workflow:plan-first`, `agentic-workflow:decompose-deliverables`)
- **Flagged "Out of scope" / "Deferred" items become Backlog issues** so
  nothing is lost. (`agentic-workflow:flagged-todo`)
- **Every Linear issue carries a Scope label** — exactly one of the `Scope`
  group (`DS`, `PM`, `Tooling`, `Shared`). One team (`PRO`) holds all work;
  scope is the cross-product filter, not the team. Add `Type` and `Discipline`
  when known. Never create an issue without a Scope label.
- **A project enters Current only when a human commits to it.** Before promoting
  work, sweep the board: close tickets superseded by newly defined work, move
  finished projects to Done (park trigger-gated leftovers in a holding project),
  and size the batch to measured velocity rather than ambition, keeping WIP
  bounded. No code begins until the project is Current and the ticket sits in
  the current cycle at Todo; you evaluate the blockers and dependencies and
  propose, the human commits. (`agentic-workflow:board-hygiene`)
- **Archiving is a GraphQL job.** The Linear MCP can read and update but cannot
  archive or delete, and archiving is what frees the workspace issue cap. Use the
  GraphQL API with a key read from 1Password.
  (`agentic-workflow:linear-archive`)
- Update the plan as the work evolves. A stale plan is worse than no plan.

## Documentation {#documentation}

Knowledge that lives only in a chat session is knowledge the next person does
not have. Write it down where it will be found:

- **The repository is the source of truth for how to build the thing.** Anything
  an agent or a new engineer must know to work here — the stack, the layering,
  the gates, the run lifecycle, the conventions — belongs in the repo, reachable
  from its README, and close to the code it describes. A rule that holds across
  Propitech projects belongs further up, in the shared baseline, not copied into
  each repo. Copying is what makes the copies disagree.
- **Notion is the source of truth for the product and the durable decisions.**
  A shipped feature gets a domain page under the product's Product & Features
  section, so someone can learn what the system does without reading it.
  (`agentic-workflow:document-feature`)
- **Claude Design is the source of truth for the design.** The locked direction
  lives in a product's Claude Design projects on claude.ai/design, and it lives
  there in every repository and at every stage of a product's life — a closed
  design phase does not hand the canon back to the code. The repository
  implements the direction; it never becomes the direction. So a component
  library published out of a repo is not a mirror that the repo may overrule:
  it exists so that explorations generate against components that really exist,
  and when the two disagree, the canvases are right and the code is the thing to
  change. Harvest direction only — never paste or ship an HTML export.
  (`agentic-workflow:design-canvas`, `agentic-workflow:tool-interfaces`)
- **A material decision is recorded when it is made, not remembered.** When a
  non-trivial architecture or design call is settled — or an earlier one is
  reversed — write it to the plan's Resolved decisions and the relevant Notion
  page. The reasoning is the part that decays; capture *why*, not just what.
  (`agentic-workflow:document-decision`)
- **Documentation ships with the change, not after it.** A feature that is not
  documented is not done, in the same way that a feature with no test is not
  done. Update the page in the pull request that changes the behaviour, while
  you still remember why.
- **A stale document is worse than a missing one**, because it is believed. When
  you find documentation contradicting the code, fix it or delete it — do not
  route around it, and do not leave the contradiction for the next reader to
  discover the hard way.
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
- **Newer baselines arrive as sync PRs**, opened by the upstream currency
  workflow in `propitech/claude-plugins` (`agents-currency.yml`, driving
  `bin/agents-sync-consumer`); review one like a dependency bump. The local
  `bin/agents-render` only re-renders the pinned version — it cannot pull a
  newer one.
- The baselines are owned upstream in `propitech/claude-plugins`. To change a
  **shared** rule, change it there (the fragment is the single source), not in
  this generated file.
- **Agent memory keeps only machine-local, non-shareable facts.** Anything
  shareable — a rule, a project fact, a decision — belongs in its owning home
  (a claude-plugins skill or fragment, this repo's docs or deltas, or Notion).
  Before saving a shareable memory, alert the user and propose that home
  instead. (`agentic-workflow:memory-policy`)

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
