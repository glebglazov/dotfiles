---
name: to-tasks
description: Break a plan, spec, or PRD into independently-grabbable work items written as local markdown files. Use when the user wants to convert a plan into tasks, create implementation tickets, or break down work into actionable items.
---

# To Tasks

Break a plan into independently-grabbable work items using vertical slices (tracer bullets).

## Process

### 1. Gather context

Work from whatever is already in the conversation context. If the user passes a task reference (task id, URL, or path) as an argument, fetch it and read its full body.

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current state of the code. Use the project's domain glossary vocabulary throughout, and respect ADRs in the area you're touching.

### 3. Draft vertical slices

Break the plan into **tracer bullet** slices. Each slice is a thin vertical slice that cuts through ALL integration layers end-to-end, NOT a horizontal slice of one layer.

Slices may be 'HITL' or 'AFK'. HITL slices contain ONLY human work — verification, decisions, manual testing; the executor never runs them. AFK slices can be implemented and merged without human interaction. Prefer AFK over HITL where possible.

If a HITL slice needs an artifact built first (a report command, test data, a harness), split it: the agent work goes in an AFK slice, and the HITL slice depends on it via "Blocked by" and contains only the human steps. A HITL slice whose "What to build" describes software is mis-typed. Write the HITL body as instructions to the human — the exact steps to verify.

Assign an `effort` to every slice using this named-signal heuristic:

- `heavy` — architectural or cross-cutting refactors, or genuinely tricky algorithms.
- `light` — large but mechanical work such as renames, codemods, config, or boilerplate.
- `standard` — everything else.

Write an explicit effort value for each task. Default to `standard` when no named signal clearly applies. Do not consult `pop tasks agents` in the default flow: effort is model-strength intent, not an agent choice.

<vertical-slice-rules>
- Each slice delivers a narrow but COMPLETE path through every layer (schema, API, UI, tests)
- A completed slice is demoable or verifiable on its own
- Prefer many thin slices over few thick ones
</vertical-slice-rules>

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each slice, show:

- **Title**: short descriptive name
- **Type**: HITL / AFK
- **Effort**: light / standard / heavy
- **Blocked by**: which other slices (if any) must complete first
- **User stories covered**: which user stories this addresses (if the source material has them)

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the dependency relationships correct?
- Should any slices be merged or split further?
- Are the correct slices marked as HITL and AFK?
- Does any HITL slice contain agent-doable work that should be split into an AFK blocker?

Iterate until the user approves the breakdown.

### 5. Commit this session's artifacts

Before creating the task set, commit the repository artifacts **this agent session** produced. The motivation is the worktree strategy: tasks are often worked in a fresh git worktree forked from the current branch's HEAD, so any CONTEXT/ADR/code this session generated must be on HEAD for the worktree to carry it.

First, decide the **task-set name** `<task-set-name>` = `<timestamp>-<slug>` now (naming rules are in step 6 — `<slug>` is either the source PRD slug without its timestamp prefix, or a hyphen-delimited summary of the work). The commit reuses `<slug>` as its scope, and the same `<task-set-name>` is used when writing the work items in step 6.

Then:

1. **Skip if nothing to do.** If the working directory is not a git repository, or this session created/modified no committable repository files, skip this step silently and proceed to step 6.
2. **Identify session paths.** From this conversation's history, list *exactly* the repository files this agent session created or modified — CONTEXT base/fragments (`CONTEXT*.md`), ADRs (`docs/adr/**`), `CONTEXT-MAP.md`, and any code or prototype the session touched. Commit CONTEXT fragments **as-is** — do not consolidate them. Do **not** include files this session never touched, even if dirty; prior-session artifacts are intentionally out of scope.
3. **Confirm.** Show the user the exact file list to be staged and the proposed commit subject. Separately, report any dirty files this session did *not* touch as "left alone — not staged" so nothing is silently swept or split. Wait for approval.
4. **Stage exactly those paths** (never `git add -A`) and create a **single commit**. The subject reuses `<slug>` as scope; the type follows content:
   - docs-only → `docs(<slug>): <summary> (ADR-NNNN + glossary)` (drop whichever parenthetical part doesn't apply)
   - mixed code + docs → a fitting conventional type (`feat`, `chore`, …), still scoped `(<slug>)`

   Write a short human `<summary>` of what the artifacts cover (e.g. `effort-model-resolution glossary + ADR-0032`), matching the repo's existing commit style.

### 6. Write the work items to the local filesystem

Resolve the tasks base directory, `<tasks-dir>`, by running `pop tasks show-path` — it prints the absolute path to this repository's task storage (in pop's data dir, outside the repo tree) and creates it on demand.

For each approved slice, write a markdown file to the `<tasks-dir>/<task-set-name>/` directory (create the subdirectory if it doesn't exist), using the `<task-set-name>` decided in step 5. Use the following template. Write them in dependency order (blockers first) so you can reference real identifiers in the "Blocked by" field.

<naming-convention>
`<timestamp>` is a human-readable local date/time prefix so task sets sort chronologically:

- Default: `YYYY-MM-DD` (e.g. `2026-05-31`)
- If a folder with the same date and slug already exists: `YYYY-MM-DD-HHMM` (24-hour local time, e.g. `2026-05-31-2036`)

Examples: `2026-05-31-user-auth`, `2026-05-31-2036-user-auth`
</naming-convention>

<task-template>
## Parent

A reference to the parent item (if the source was an existing file, otherwise omit this section).

## What to build

A concise description of this vertical slice. Describe the end-to-end behavior, not layer-by-layer implementation.

Avoid specific file paths or code snippets — they go stale fast. Exception: if a prototype produced a snippet that encodes a decision more precisely than prose can (state machine, reducer, schema, type shape), inline it here and note briefly that it came from a prototype. Trim to the decision-rich parts — not a working demo, just the important bits.

## Type

HITL or AFK.

## Acceptance criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Blocked by

- A reference to the blocking item (if any)

Or "None - can start immediately" if no blockers.

</task-template>

Use a consistent filename scheme: `<number>-<task-name>.md`, e.g. `01-login-form.md`. The set-relative task target reference for that task is `<task-set-name>/<number>-<task-name>.md`, e.g. `2026-05-31-user-auth/01-login-form.md`.

Do NOT close or modify any parent file.

### 7. Write the sidecar JSON manifest

Alongside the markdown files, write `<tasks-dir>/<task-set-name>/index.json` — a machine-readable manifest that a ralph loop (or any automation) can rely on to track completion and unblock ordering. Each entry mirrors one markdown file.

<manifest-schema>
```json
{
  "tasks": [
    {
      "id": "01-login-form",
      "file": "01-login-form.md",
      "title": "Login form",
      "type": "AFK",
      "effort": "standard",
      "status": "open",
      "blocked_by": []
    }
  ]
}
```
</manifest-schema>

Field rules:

- `id` — the filename stem (`<number>-<task-name>`), stable identifier referenced by `blocked_by`.
- `status` — one of `open` | `done` | `failed` | `skipped`. Always initialize to `open`. Do not write `in_progress`; persisted `in_progress` is malformed.
- `blocked_by` — array of `id`s of blocking tasks. Empty array if none.
- `type` — `HITL` or `AFK`, matching the markdown.
- `effort` — one of `light` | `standard` | `heavy`. Write it explicitly for new tasks using the named-signal heuristic above. If absent in an existing manifest, it means `standard`.
- `agent` — optional escape hatch from ADR-0018. Fill it only when the user explicitly asks for a specific agent or model for a task; it is not part of the default planning flow.
- `failed_after` — optional integer; the number of attempts after which a runner gave up. Written only when `status` becomes `failed`.

The JSON is the source of truth for automation. The rules above — the eligibility condition (`status == "open"` and every `blocked_by` id is satisfied by a task whose status is `done` or `skipped`, preferring `AFK` over `HITL` among eligible tasks), the done-condition (all `## Acceptance criteria` boxes checked), and the commit format `tasks(<task-set-slug>): <id>` (set name without its timestamp prefix) — are the **contract** implemented by `pop tasks implement`, which drains the whole set or runs one task when given a `<task-set>/<file>.md` target.

Keep `index.json` and the markdown files in sync — every markdown file has exactly one manifest entry and vice versa.

### 8. Verify registration

Run `pop tasks status <task-set-name>` to trigger pop's lazy discovery and confirm the set registered correctly. Pop prints `Registered new task set(s): <task-set-name>` on first sighting.

Check the output:

- The task set appears in the table with status `READY` (or `DEFERRED` if every open task is HITL).
- It is **not** `MALFORMED` or `MISSING`.

If `MALFORMED`, read the diagnostics, fix the markdown/manifest issues they name, and re-run `pop tasks status <task-set-name>` until the set is `READY` or `DEFERRED`.

Tell the user the task-set name, its status, and how many tasks are open.
