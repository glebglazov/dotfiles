---
name: to-issues
description: Break a plan, spec, or PRD into independently-grabbable work items written as local markdown files. Use when the user wants to convert a plan into issues, create implementation tickets, or break down work into actionable items.
---

# To Issues

Break a plan into independently-grabbable work items using vertical slices (tracer bullets).

## Process

### 1. Gather context

Work from whatever is already in the conversation context. If the user passes an issue reference (issue number, URL, or path) as an argument, fetch it and read its full body.

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current state of the code. Use the project's domain glossary vocabulary throughout, and respect ADRs in the area you're touching.

### 3. Draft vertical slices

Break the plan into **tracer bullet** slices. Each slice is a thin vertical slice that cuts through ALL integration layers end-to-end, NOT a horizontal slice of one layer.

Slices may be 'HITL' or 'AFK'. HITL slices require human interaction, such as an architectural decision or a design review. AFK slices can be implemented and merged without human interaction. Prefer AFK over HITL where possible.

<vertical-slice-rules>
- Each slice delivers a narrow but COMPLETE path through every layer (schema, API, UI, tests)
- A completed slice is demoable or verifiable on its own
- Prefer many thin slices over few thick ones
</vertical-slice-rules>

### 4. Quiz the user

Present the proposed breakdown as a numbered list. For each slice, show:

- **Title**: short descriptive name
- **Type**: HITL / AFK
- **Blocked by**: which other slices (if any) must complete first
- **User stories covered**: which user stories this addresses (if the source material has them)

Ask the user:

- Does the granularity feel right? (too coarse / too fine)
- Are the dependency relationships correct?
- Should any slices be merged or split further?
- Are the correct slices marked as HITL and AFK?

Iterate until the user approves the breakdown.

### 5. Write the work items to the local filesystem

For each approved slice, write a markdown file to the project's `docs/issues/<prd-name>/` directory (create it if it doesn't exist, inferring `<prd-name>` from context or asking the user). Use the following template. Write them in dependency order (blockers first) so you can reference real identifiers in the "Blocked by" field.

<issue-template>
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

</issue-template>

Use a consistent filename scheme: `<number>-<issue-name>.md`, e.g. `docs/issues/user-auth/01-login-form.md`.

Do NOT close or modify any parent file.

### 6. Write the sidecar JSON manifest

Alongside the markdown files, write `docs/issues/<prd-name>/index.json` — a machine-readable manifest that a ralph loop (or any automation) can rely on to track completion and unblock ordering. Each entry mirrors one markdown file.

<manifest-schema>
```json
{
  "issues": [
    {
      "id": "01-login-form",
      "file": "01-login-form.md",
      "title": "Login form",
      "type": "AFK",
      "status": "open",
      "blocked_by": []
    }
  ]
}
```
</manifest-schema>

Field rules:

- `id` — the filename stem (`<number>-<issue-name>`), stable identifier referenced by `blocked_by`.
- `status` — one of `open` | `in_progress` | `done`. Always initialize to `open`.
- `blocked_by` — array of `id`s of blocking issues. Empty array if none.
- `type` — `HITL` or `AFK`, matching the markdown.

The JSON is the source of truth for automation: a loop picks the next issue whose `status` is `open` and whose `blocked_by` are all `done`, then flips `status` to `done` when the markdown acceptance criteria are all checked. Keep `index.json` and the markdown files in sync — every markdown file has exactly one manifest entry and vice versa.
