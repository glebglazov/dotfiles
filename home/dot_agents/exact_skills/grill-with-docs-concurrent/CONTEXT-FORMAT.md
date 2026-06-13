# CONTEXT.md Format

## Structure

```md
# {Context Name}

{One or two sentence description of what this context is and why it exists.}

## Language

**Order**:
{A one or two sentence description of the term}
_Avoid_: Purchase, transaction

**Invoice**:
A request for payment sent to a customer after delivery.
_Avoid_: Bill, payment request

**Customer**:
A person or organization that places orders.
_Avoid_: Client, buyer, account
```

## Rules

- **Be opinionated.** When multiple words exist for the same concept, pick the best one and list the others under `_Avoid_`.
- **Keep definitions tight.** One or two sentences max. Define what it IS, not what it does.
- **Only include terms specific to this project's context.** General programming concepts (timeouts, error types, utility patterns) don't belong even if the project uses them extensively. Before adding a term, ask: is this a concept unique to this context, or a general programming concept? Only the former belongs.
- **Group terms under subheadings** when natural clusters emerge. If all terms belong to a single cohesive area, a flat list is fine.

## Single vs multi-context repos

**Single context (most repos):** One `CONTEXT.md` at the repo root.

**Multiple contexts:** A `CONTEXT-MAP.md` at the repo root lists the contexts, where they live, and how they relate to each other:

```md
# Context Map

## Contexts

- [Ordering](./src/ordering/CONTEXT.md) — receives and tracks customer orders
- [Billing](./src/billing/CONTEXT.md) — generates invoices and processes payments
- [Fulfillment](./src/fulfillment/CONTEXT.md) — manages warehouse picking and shipping

## Relationships

- **Ordering → Fulfillment**: Ordering emits `OrderPlaced` events; Fulfillment consumes them to start picking
- **Fulfillment → Billing**: Fulfillment emits `ShipmentDispatched` events; Billing consumes them to generate invoices
- **Ordering ↔ Billing**: Shared types for `CustomerId` and `Money`
```

The skill infers which structure applies:

- If `CONTEXT-MAP.md` exists, read it to find contexts
- If only a root `CONTEXT.md` exists, single context
- If neither exists, create a root `CONTEXT.md` lazily when the first term is resolved

When multiple contexts exist, infer which one the current topic relates to. If unclear, ask.

## Concurrent writes: fragments

`CONTEXT.md` is one shared file. When agents run in parallel — or a team uses this skill — concurrent writes to it conflict. The fix: **never write the base file during a normal session.** Each session writes its own delta fragment; readers union base + fragments; a human folds fragments back in on demand.

### Write to your own fragment

The first time a session resolves a term, create one fragment beside the base it deltas:

```
<dir>/CONTEXT.<uuid>.md      # uuid from: uuidgen | head -c8
```

Reuse that one file for every term you resolve this session. It's co-located with its base `CONTEXT.md` (same directory — in multi-context repos, the context's own dir). Because every session writes a *different* file, parallel work never collides.

A fragment is a list of **delta ops**, not a full glossary:

```md
---
fragment: 8f3a2c1d
branch: feat/settlement      # or task id — where this came from
---

+ Settlement
  Funds moved from escrow to the merchant after dispatch.
  avoid: payout, transfer
  under: Payments

~ Order
  An agreement to supply goods at an agreed price.
  was: A request from a customer to purchase goods.

- Buyer
```

- `+ Term` — **add** a new term. Body is the definition; optional `avoid:` and optional `under: <heading>` placement hint.
- `~ Term` — **redefine** an existing term. New definition, plus a `was:` snapshot of the base definition *at the moment you edited it* — so a later consolidation can tell if the base drifted underneath.
- `- Term` — **retire** a term.

Provenance is just `fragment:` (= the uuid) and `branch:`/task. Don't track commit SHAs — the fragment rides in the same commit as the change that motivated it, so `git log --follow` is your index for free.

### Read = union, in memory

The effective glossary is **base `CONTEXT.md` overlaid with every `CONTEXT.*.md` in the same directory**, computed at read time. This is read-only — globbing and unioning never mutates a file, so it never conflicts. Glob the fragments at session start and treat the union as the glossary you challenge terms against.

Overlay rules:

- A fragment op beats the base (`~` redefinition wins over the base definition; `-` removes it).
- **Two fragments touching the same term = collision.** Render both, marked `⚠ contested — needs consolidation`. Do *not* silently pick one. This is where a genuine semantic conflict announces itself instead of hiding.
- A `+` term whose `under:` matches an existing heading slots there; with no hint or a novel heading, it renders under `## Unfiled (pending consolidation)`.

### Consolidate: manual, single-writer

Folding fragments into the base is the **only** operation that mutates `CONTEXT.md`, so it must have exactly one writer. Run it on demand — when fragments pile up, or before a release — as a deliberate grill-with-docs-concurrent session, never automatically and never in parallel. In that session:

1. Apply each `+`/`~`/`-` op into the base `CONTEXT.md`.
2. File `## Unfiled` terms into their real sections.
3. Resolve every `⚠ contested` term — these are semantic conflicts, so grill the human for the canonical definition.
4. Delete the fragments you folded in.

`CONTEXT-MAP.md` is **not** fragmented — adding or rewiring a context is rare and structural, so tolerate the occasional conflict or settle it during consolidation.
