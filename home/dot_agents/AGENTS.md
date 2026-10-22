# Global Instructions

Always talk in ASD-STE100 Simplified Technical English. Always read GLOSSARY.md or GLOSSARY-MAP.md files (or the legacy CONTEXT.md or CONTEXT-MAP.md), and use their ubiquitous language. Run all prose you write (replies, commit messages, PR bodies, docs) through `pstack:unslop` where you have it.

## RTK

`rtk` filters verbose command output. Claude Code, Cursor, pi and OpenCode
rewrite shell commands through it automatically, so expect rtk-shaped output.
In Codex and Amp, run `rtk <cmd>` yourself when output is likely to be large.

- `rtk proxy <cmd>` runs a command unfiltered. Use it when rtk's filtering is
  hiding output you need.
- `rtk find` rejects compound predicates and actions (`-not`, `-exec`, …). Use
  `rg --files` or `rtk proxy find` instead.
- Do not run `rtk init`. Chezmoi manages this file and every agent's rtk
  wiring, and `rtk init` rewrites them.

## Secrets

Environment values written as 1Password references (`op://vault/item/field`) are
not secrets yet — they are pointers. Resolve them with `op-cache`, a caching
proxy over `op` that keeps repeated reads fast.

- `op-cache run <cmd>` runs a command with every `op://` value in its
  environment resolved. Use it whenever a command needs a secret.
- `op-cache read op://vault/item/field` gets one value.
- Resolved secrets are masked in the output. If the command must print one —
  a token you then pass on — add `--no-masking`.
- Never `op read` a secret to paste it into a file, a commit, or your reply.

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
- **Images are permanent context.** A screenshot read at turn 60 is re-billed for
  every turn after it. Read one when visual judgment is genuinely the question;
  don't hold variant pairs side by side.
- **Drive interactive tools from a script, not from the prompt.** A browser or
  REPL session stepped one statement per shell call spends hundreds of turns on
  work one file would do in a single run. Write the script to a temp file, run it
  once, print every assertion.

## Opening pages in a browser

Open every page your reply delivers to me: a PR you opened, an HTML file or
artifact I asked for, a preview, a deployed site, a Lavish review. A page you only
cite as a source stays a link. To open one, run `muxify browser available`, then
use the opener its answer picks:

- `local` or `remote`: `muxify browser open <url>`.
- `no` (exit status 1, a normal result), or no `muxify` command: the default
  browser (`open` on macOS, `xdg-open` on Linux).

Open the Tailscale URL when the page has one. It works on the Mac and on my
other machines, and for `remote` my Mac can reach only that address.
`localhost` is the Mac.

If the tool that serves the page opens a browser by itself, start it with its
no-open option, so the page opens only once. For Lavish, that is `--no-open`.
Before you run `lavish-axi`, read `~/.agents/docs/lavish.md`.

## Implementation

Before you write or change code, run `pop conventions get implementation` and
follow every line it prints. It resolves to the standard in force for the
repository you are in — its own, where the team has written one.

## Git

Before you write a commit, run `pop conventions get commits` and follow every
line it prints.

Never create a branch unless I ask for one. Work on the branch that is already
checked out, even if it is the default branch. If you think the change belongs on
its own branch, say so and let me decide — do not switch or create anything first.

## Opinions

### Assessing solutions

Do not weigh implementation time. Propose the most correct and most maintainable
solution available, and let me decide on scope. "Faster to build" is not a
tiebreaker and should not be offered as one.

### HTML pages

An HTML page you write follows the OS light/dark setting. Put
`<meta name="color-scheme" content="light dark">` in `<head>`, and give the dark
values under `@media (prefers-color-scheme: dark)`. With DaisyUI, leave
`data-theme` off `<html>`: its `themes.css` switches by itself. Use one fixed
theme only when I ask for one, or when the page shows a product that has only
one theme.

### Comments

A comment explains one of two things, chosen by where it sits:

- **Low-level code** — explain the abstraction it serves. What does the caller
  get from this? Why does the higher-level design need it?
- **A low-level abstraction itself** — go the other way and get concrete.
  Explain what actually happens when this runs.

Be brief. If neither direction applies, write no comment.
