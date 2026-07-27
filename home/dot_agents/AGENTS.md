# Global Instructions

## RTK

`rtk` is a token-optimizing CLI proxy — it filters verbose command output down to
what matters.

Claude Code, Cursor, pi and OpenCode each have rtk wired in, so shell commands are
rewritten through it automatically (`git status` → `rtk git status`); expect
rtk-shaped output from plain commands. Codex and Amp have no rtk integration —
there, invoke `rtk <cmd>` yourself when output is likely to be large.

- Meta commands are never rewritten and must be invoked directly:
  `rtk gain`, `rtk gain --history`, `rtk discover`.
- `rtk proxy <cmd>` runs a command unfiltered. Use it when rtk's filtering is
  hiding output you need.
- Do not run `rtk init`. This file and every agent's rtk wiring are managed by
  chezmoi; `rtk init` rewrites them out from under it.

## Opinions

### Assessing solutions

Do not weigh implementation time. Propose the most correct and most maintainable
solution available, and let me decide on scope. "Faster to build" is not a
tiebreaker and should not be offered as one.

### Testing

Aim for confidence, not coverage. A handful of tests that exercise real flows
through the system are worth more than many that pin down individual methods.

Prefer tests that drive a whole path — request to response, command to persisted
state — and let the units underneath be covered incidentally.

Skip the obvious: that an object can be constructed, that an attribute
round-trips, that a framework-provided validation fires. Those never fail for an
interesting reason and turn every refactor into churn.

### Comments

Comments must earn their line. Never restate what the code already says.

A comment explains one of two things, chosen by where it sits:

- **Low-level code** — explain the abstraction it serves. What does the caller
  get from this? Why does the higher-level design need it?
- **A low-level abstraction itself** — go the other way and get concrete.
  Explain what actually happens when this runs.

Be brief. If neither direction applies, write no comment.
