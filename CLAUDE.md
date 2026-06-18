# CLAUDE.md

Auto-loaded by Claude Code at session start. Source of truth for
agent behaviour is [`AGENTS.md`](AGENTS.md) — read it in full.

@AGENTS.md

---

## Claude-Code-specific notes

These deltas apply only when the harness is Claude Code. Everything
else lives in `AGENTS.md`.

### Working style

- Use `Read`, `Edit`, `Write` for files; reserve `Bash` for shell
  work (git, rspec, rubocop, qlty, mise).
- Run all gates before reporting done — see [AGENTS.md#gates-ruby-gem](AGENTS.md#gates-ruby-gem).
- Plan-first rule from [AGENTS.md#plan-first](AGENTS.md#plan-first) is binding.
  If the user gives a vague task, draft the plan in Linear and ask for
  sign-off before coding.

### Tone

Default to terse, technical, plain text. Match formality to the
human in the loop. Code, commits, and PR bodies are always written
in normal prose regardless of any conversational compression mode.
