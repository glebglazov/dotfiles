---
name: run-one
description: >-
  Pick and implement exactly one issue from a to-issues manifest (index.json).
  Explicit invocation only — use when the user types /run_one (Cursor) or
  $run-one (Codex) with an issues folder.
disable-model-invocation: true
---

# Run One

Implement **exactly one** issue from a `thoughts/issues/<issue-set-name>/` folder, in this
agent's own context (no subprocess). Source of truth: `<issues-folder>/index.json`
(see the **to-issues** skill for the full manifest contract).

This skill is pure prose by design — it depends on nothing on `$PATH`. You do the
deterministic steps yourself by following the contract below.

## Invocation

**Explicit only.** Run this workflow only when the user typed `/run_one` (Cursor)
or `$run-one` (Codex). Natural-language requests are not sufficient — tell the
user to invoke it explicitly.

`/run_one <issues-folder> [issue-file]`

`<issues-folder>` is e.g. `thoughts/issues/user-auth`. The optional `issue-file`
forces a specific issue instead of picking the next eligible one.

## Workflow

### 1. Preflight

- Confirm `<issues-folder>/index.json` exists and you are inside a git repo.
- Confirm the working tree is clean (`git status --porcelain` is empty). If it
  is dirty, stop and tell the user (unless they say to proceed anyway).
- Load domain knowledge. Check the repo root for `CONTEXT-MAP.md` and `CONTEXT.md`
  (the docs produced by the **grill-with-docs** skill):
  - If `CONTEXT-MAP.md` exists, the repo has multiple bounded contexts — read it,
    then read the per-context `CONTEXT.md` it points at that is relevant to this
    issue set.
  - Else if a root `CONTEXT.md` exists, read it (single context).
  - If neither exists, skip — there is no domain glossary to honour.

  Use this as the project's glossary: match its terminology in code, names, and
  commit messages. If the issue uses a term that conflicts with `CONTEXT.md`,
  flag it rather than silently guessing.

### 2. Pick the next issue

Read `index.json`. Pick the target issue:

- If `issue-file` was given, use that entry.
- Otherwise pick the next eligible issue, where eligible means:
  `status == "open"` **and** every id in `blocked_by` resolves to an issue that
  is *satisfied* — i.e. its `status` is `"done"` **or** `"skipped"` (a skipped
  issue is deliberately set aside, but it still unblocks its dependents). A
  missing blocker id counts as not-satisfied. Among eligible issues, prefer
  `AFK` over `HITL` (in manifest order within each group) so you don't stall on a
  human-in-the-loop slice while an autonomous one is ready.

Valid `status` values are `open`, `done`, `failed`, and `skipped`. Only `open`
issues are runnable.

If nothing is eligible, stop and report that there is nothing to do.

### 3. Implement

- Read the issue markdown in full, plus any parent/PRD it references (the
  `## Parent` section).
- Build the work described under `## What to build`.
- Satisfy every checkbox under `## Acceptance criteria`, and **check the boxes**
  (`- [ ]` → `- [x]`) in the markdown as you complete them.
- Do **not** edit `index.json` or `progress.txt` yet, and do **not** commit yet.

### 4. Verify

Confirm every checkbox under `## Acceptance criteria` (up to the next `##`
heading) is checked. If any remain unchecked, the issue is not done — keep
working or, if genuinely blocked, jump to the failure path in step 5.

### 5. Commit

On success:

1. In `index.json`, set this issue's `status` to `"done"`.
2. Append a block to `<issues-folder>/progress.txt`:
   ```
   <UTC ISO-8601 timestamp> [<issue-file>] DONE
   <one or more summary lines>
   ---
   ```
3. `git add -A` and commit. Subject must be **`workload(<issue-set-name>): <issue-id>`**
   with the summary as the body, where `<issue-set-name>` is the issues-folder
   basename and `<issue-id>` is the full manifest `id` (e.g. set `user-auth`, id
   `01-login-form` → subject `workload(user-auth): 01-login-form`). This matches
   the `pop` `workload` runner's commit contract exactly, so inline and batch runs
   produce uniform history.

If abandoning (blocked, unclear, repeatedly failing):

1. In `index.json`, set `status` to `"failed"` and add `failed_after` = number
   of attempts.
2. Append a `FAILED` block to `progress.txt` with the reason.
3. **Do not commit.** Like the `pop` runner, a failed issue is *not* committed —
   write the manifest and `progress.txt` updates to disk and leave the partial
   work tree dirty for the user to inspect or discard. Report what was attempted
   and why it failed.

Keep `index.json` and the markdown in sync — every markdown file has exactly one
manifest entry and vice versa.
