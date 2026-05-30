---
name: run-one
description: >-
  Pick and implement the next eligible issue from a to-issues manifest
  (index.json). Use when the user invokes /run_one, asks to run the next issue,
  work one slice from docs/issues, or implement the next AFK tracer bullet.
disable-model-invocation: true
---

# Run One

Implement **exactly one** issue from a `docs/issues/<prd-name>/` folder, in this
agent's own context (no subprocess). Source of truth: `<issues-folder>/index.json`
(see the **to-issues** skill for the full manifest contract).

This skill is pure prose by design — it depends on nothing on `$PATH`. You do the
deterministic steps yourself by following the contract below. (For unattended
batch runs there is a separate standalone tool, `issue run-all` /
`issue run-all-parallel`, which is an independent implementation of the same
contract — do not call it from here.)

## Invocation

`/run_one <issues-folder> [issue-file]`

`<issues-folder>` is e.g. `docs/issues/user-auth`. The optional `issue-file`
forces a specific issue instead of picking the next eligible one.

## Workflow

### 1. Preflight

- Confirm `<issues-folder>/index.json` exists and you are inside a git repo.
- Confirm the working tree is clean (`git status --porcelain` is empty). If it
  is dirty, stop and tell the user (unless they say to proceed anyway).

### 2. Pick the next issue

Read `index.json`. Pick the target issue:

- If `issue-file` was given, use that entry.
- Otherwise pick the next eligible issue, where eligible means:
  `status == "open"` **and** every id in `blocked_by` resolves to an issue whose
  `status == "done"`. A missing blocker id counts as not-done. Among eligible
  issues, prefer `AFK` over `HITL` (in manifest order within each group) so you
  don't stall on a human-in-the-loop slice while an autonomous one is ready.

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
3. `git add -A` and commit with subject **`[<prd-name> <number>] <name>`** and
   the summary as the body, where `<prd-name>` is the issues-folder basename,
   `<number>` is the numeric prefix of the issue id, and `<name>` is the rest of
   the id (e.g. id `01-login-form` → `[user-auth 01] login-form`).

If abandoning (blocked, unclear, repeatedly failing):

1. In `index.json`, set `status` to `"failed"` and add `failed_after` = number
   of attempts.
2. Append a `FAILED` block to `progress.txt` with the reason.
3. Commit with subject `[<prd-name> <number>] <name> — failed after N tries`.

Keep `index.json` and the markdown in sync — every markdown file has exactly one
manifest entry and vice versa.
