# Global Instructions

Always talk in ASD-STE100 Simplified Technical English. Always read CONTEXT.md or CONTEXT-MAP.md files, and use their ubiquitous language.

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
- `rtk find` rejects compound predicates and actions (`-not`, `-exec`, …). Don't
  retry variations — reach for `rg --files` or `rtk proxy find` instead.
- Do not run `rtk init`. This file and every agent's rtk wiring are managed by
  chezmoi; `rtk init` rewrites them out from under it.

## Tool economy

Context is billed on every turn and only grows, so a session's cost rises with
the square of how many tool calls it takes. Fewer, fatter calls beat many thin
ones.

- **Absolute paths, one shell call.** Shell state doesn't carry between calls.
  Don't `cd` somewhere and `cd` back next call; don't re-export the same env line
  repeatedly — chain setup and command together, or put the setup in a script and
  run that.
- **Probe wide once.** One `rg` across the tree beats a ladder of narrowing greps.
  If two searches for the same symbol come back empty, the search shape is wrong —
  switch to LSP go-to-definition or read the file that owns the type, don't try a
  third pattern.
- **Never re-run for output already in context.** Re-reading a file you just read
  or re-running a build whose output you have pays twice for one fact.
- **Images are permanent context.** A screenshot read at turn 60 is re-billed for
  every turn after it. Read one when visual judgment is genuinely the question;
  don't hold variant pairs side by side.
- **Drive interactive tools from a script, not from the prompt.** A browser or
  REPL session stepped one statement per shell call spends hundreds of turns on
  work one file would do in a single run. Write the script to a temp file, run it
  once, print every assertion.

## Git

Never create a branch unless I ask for one. Work on the branch that is already
checked out, even if it is the default branch. If you think the change belongs on
its own branch, say so and let me decide — do not switch or create anything first.

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
