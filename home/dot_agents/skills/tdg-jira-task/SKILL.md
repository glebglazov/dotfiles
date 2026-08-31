---
name: tdg-jira-task
description: >-
  Draft a JIRA task (summary + description) from work in the current
  conversation and its diff. Use when the user wants a task/story/ticket
  description written — "draft a jira task", "write the task description",
  "describe this as a ticket" — or when another skill (e.g. tdg-task-commit)
  needs task content. Produces neutral Markdown and stops at a user-approved
  draft; the caller owns delivery and format rendering.
---

# TDG JIRA task

Produce a task summary and description from work that (usually) already
exists — the conversation, the diff, and its specs. Output is Markdown with
this shape:

```
<Summary: imperative, plain, no bracketed [Area] tag>

<Lead sentence: one sentence stating what changed.>

## Context

<2–4 sentences: the trigger for this work, and the precedent ticket link
if the work extends prior behavior.>

## Scope

* <one observable delta>
  * <sub-detail of that delta>
* <another delta>

## Before launch   (only when ops prerequisites exist)

* <provisioning / registration step someone must do before release>

## Acceptance criteria

* **AC01:** <stimulus → observable outcome>
* **AC02:** <...> (manual)
```

## Audience split

Context is plain language, readable by anyone on the team. Scope and
acceptance criteria are written for the **verifier** — the QA engineer or
reviewer who must check the work — so they name the **observable surface**:
endpoints, HTTP statuses, event names, persisted state, rendered UI elements —
anything visible from outside the running process. `POST /callback answers
401` is on the surface; `BesitosContract raises ValidationError` is not. The
one internal worth quoting verbatim is a production error string being fixed —
that is the searchable signal.

## Step 1 — Gather substance and terminology

The substance comes from the conversation: what was built, why, what was
agreed. Where the conversation is thin, read the diff and its spec files
(`git diff`, `git show`) — you will need the specs in Step 3 regardless.

Domain terminology follows this authority order:

1. the user's own words in the conversation;
2. the repo's `CONTEXT.md` / `CONTEXT-MAP.md` ubiquitous language;
3. the precedent ticket (Step 2) — how the team wrote about this area before;
4. code identifiers — weakest: teams often speak a different dialect than the
   schema (`monetization_products` in code was "incent partner" to the team).

A term whose only source is code gets **flagged at the checkpoint** for the
user to confirm, never silently coined.

## Step 2 — Find the precedent

Take the JIRA project key and site host (the `cloudId`) from the caller when
another skill invoked this one; otherwise read them from the repo's JIRA
workflow or config (e.g. `.github/workflows`), and ask the user if neither
source has them.

When the work extends existing behavior, make **one** JQL attempt
(`mcp__atlassian__searchJiraIssuesUsingJql`) to find the ticket that shipped
the precedent, and cite its key in Context — JIRA autolinks it, and one key
replaces a paragraph of retold history. One attempt: if it doesn't surface
the ticket, refer to the precedent descriptively and move on. Slack threads
or PR links already in the conversation may go in Context as bare URLs.

## Step 3 — Compose

**Summary** — imperative and plain (`Add Besitos as a second incent partner`),
carrying no bracketed `[Area]`/`[Game]` prefix.

**Lead sentence** — states *what changed*, one sentence, then stops. The why
lives in Context; the value is self-evident or absent. Guardrails: a trailing
benefit clause ("…so the next partner is configuration rather than new code")
is selling, cut it; a claim about future work is speculation, cut it or state
the present fact as a Scope bullet.

**Context** — 2–4 sentences: the trigger (why this work exists now) and the
precedent link. Whatever Scope will say, Context leaves unsaid.

**Scope** — one bullet = one observable delta = one thing the verifier can
point at and call done or not done, all bullets at the same altitude. Nested
bullets hold sub-details of their parent delta only. Compress against
precedent where it applies: "linking works like the existing Freecash flow,
except: the callback is a signed GET; the player reference arrives as
`user_id`". Ops prerequisites (secrets provisioned, callback URL registered)
go under **Before launch**, so nobody mistakes them for shipped behavior.
Each fact appears in exactly one section — a delta stated in Scope is not
restated as an AC, and an invariant worth asserting ("Freecash callbacks
unchanged") lives only in the ACs.

**Acceptance criteria** — three disciplines:

- *Selection.* The happy/critical path of the new behavior is fully covered.
  Failure modes **novel to this feature** (a signature check this feature
  introduces) get ACs; standard system behavior (generic 404s, framework
  validation) does not. Aim for the minimum set that fully covers what's new;
  merge criteria that state the same rule across areas.
- *Phrasing.* Each AC is stimulus → observable outcome: "A Besitos callback
  with a missing or wrong signature is rejected with 401 and links nothing."
- *Verification.* While composing, check each AC against the diff's specs:
  an AC no spec exercises is either genuinely manual — mark it `(manual)` —
  or a **coverage gap** to flag at the checkpoint. The check stays out of the
  task text: specs are code that moves and gets deleted, so the description
  never cites spec files. Specs are free to cover more than the ACs state;
  happy-path behavior with no spec is always a gap.

Scope holds only what was discussed and agreed; anything marked out of scope
during the work stays out.

## Step 4 — Checkpoint

Show the user the complete draft plus a flag list:

- the precedent ticket key you found (confirm it's the right one);
- every code-derived term awaiting the team's real word;
- every AC marked `(manual)`;
- every coverage gap.

The step completes when the user approves the draft (possibly after edits).
Hand the approved Markdown back to the caller — or, when invoked directly,
print it and offer to create the issue.
