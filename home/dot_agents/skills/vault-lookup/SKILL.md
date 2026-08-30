---
name: vault-lookup
description: >-
  Answer a question from Gleb's Obsidian vault — his notes, his Efforts, what he
  decided or thought about a topic, whether he wrote anything on it. Read-only.
  Use from a repository outside the vault. Stay dormant when the working
  directory is already inside the vault: its own rules and skills apply there.
---

# Vault Lookup

Read Gleb's Obsidian vault from a session outside it, and answer with the paths
the answer came from. The vault holds its own retrieval rules; this skill points
at them rather than copying them, so the two never drift.

**Read-only, in every zone.** Never create, edit or delete a file in the vault —
not a note, not a capture, not an `AI/` file. A request to write goes back to
Gleb, to do in a vault session.

## 1. Resolve the vault, or stop

Take the first of these that is a directory:

1. `$OBSIDIAN_VAULT_PATH`
2. `~/Dev/mixed/obsidian_vaults/glebglazov`

If neither is, say the vault is not reachable on this machine and stop. Do not
guess a path, and do not answer the question from memory.

If the current working directory is inside the resolved vault, this skill does
not apply — say so and use the vault's own instructions, which are already
loaded there.

## 2. Load the vault's rules

Read two files, in this order:

- `<vault>/AGENTS.md` — the layout, the One-Way Rule, and the retrieval rules
  you are about to follow. **This file is the authority.** Where it disagrees
  with anything below, it wins.
- `<vault>/AI/NOTES.md` — Vault Memory: Gleb's shorthand, standing corrections
  and conventions. No search reaches it, and it often holds the answer itself.

When the question is about the vault's own design rather than its content, also
read the glossary: `<vault>/.grill-context/*.md` as one union, newest generation
winning.

## 3. Retrieve

Run the retrieval in a **blocking sub-agent**, so the notes it reads stay out of
this session's context and only the answer comes back. Give it the resolved
vault path, the question, and this file's rules. One exception: when the
question names a single note or a single Effort, read that file inline — one
`qmd get` does not earn an agent.

**Check qmd before trusting it.** `qmd collection list` prints each collection's
path. If qmd is missing, or the printed paths are not inside the resolved vault,
qmd is unusable on this machine: fall back to `rg` over the vault, and say in
the answer that you did.

With qmd usable, follow `AGENTS.md`: qmd first for a question of meaning, `rg`
when the answer is a complete set or lives in an Index Blind Spot (`AI/` folders,
`+/`, `System/`, anything written since the last embed).

**An absence claim needs an `rg` pass.** A qmd miss alone never supports "Gleb has
nothing about this".

## 4. Answer

- Prose, with **vault-relative paths** as citations: `Efforts/Tracking/VCDR/Effort.md`.
- Quote only the lines that carry the answer.
- Name the retrieval path used — qmd, or the `rg` fallback — so a thin answer is
  read as thin, not as an absence.
- The content answers the question **in the conversation**. Ask Gleb before you
  write any of it into a file of the repository you are working in.
