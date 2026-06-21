# ADR Format

ADRs live in `docs/adr/` and use **sequential ids**: `NNNN-slug.md`, zero-padded to four digits (e.g. `0001-event-sourced-orders.md`, `0002-postgres-for-write-model.md`).

Create the `docs/adr/` directory lazily — only when the first ADR is needed.

## Ids

Pick the next number naively: scan the target `docs/adr/`, take the highest existing `NNNN`, add 1, and zero-pad to four digits. The very first ADR in a directory is `0001`. Numbering is **per directory** — each `docs/adr/` (the system-wide one plus any per-context ones) has its own independent sequence.

Don't lock, and don't hunt for gaps to fill — just take max+1. Under parallel agents or teammates, two ADRs **may** land on the same number. That's expected and fine: `grill-consolidate` resolves clashes later (re-sequencing the loser and fixing links). Drop your ADR and move on.

## Template

```md
# {Short title of the decision}

{1-3 sentences: what's the context, what did we decide, and why.}
```

That's it. An ADR can be a single paragraph. The value is in recording *that* a decision was made and *why* — not in filling out sections.

## Optional sections

Only include these when they add genuine value. Most ADRs won't need them.

- **Status** frontmatter (`proposed | accepted | deprecated | superseded by ADR-NNNN`) — useful when decisions are revisited
- **Considered Options** — only when the rejected alternatives are worth remembering
- **Consequences** — only when non-obvious downstream effects need to be called out

## Cross-references

Reference another ADR by its number as `ADR-NNNN` (e.g. `superseded by ADR-0007`), or link to its file (`[...](0007-slug.md)`). Filename links are the most robust — the slug survives a renumber, so consolidate can always rewrite them unambiguously. A bare `ADR-NNNN` reference becomes ambiguous if that number was ever involved in a clash, so prefer filename links where you can.

## When to offer an ADR

All three of these must be true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful
2. **Surprising without context** — a future reader will look at the code and wonder "why on earth did they do it this way?"
3. **The result of a real trade-off** — there were genuine alternatives and you picked one for specific reasons

If a decision is easy to reverse, skip it — you'll just reverse it. If it's not surprising, nobody will wonder why. If there was no real alternative, there's nothing to record beyond "we did the obvious thing."

### What qualifies

- **Architectural shape.** "We're using a monorepo." "The write model is event-sourced, the read model is projected into Postgres."
- **Integration patterns between contexts.** "Ordering and Billing communicate via domain events, not synchronous HTTP."
- **Technology choices that carry lock-in.** Database, message bus, auth provider, deployment target. Not every library — just the ones that would take a quarter to swap out.
- **Boundary and scope decisions.** "Customer data is owned by the Customer context; other contexts reference it by ID only." The explicit no-s are as valuable as the yes-s.
- **Deliberate deviations from the obvious path.** "We're using manual SQL instead of an ORM because X." Anything where a reasonable reader would assume the opposite. These stop the next engineer from "fixing" something that was deliberate.
- **Constraints not visible in the code.** "We can't use AWS because of compliance requirements." "Response times must be under 200ms because of the partner API contract."
- **Rejected alternatives when the rejection is non-obvious.** If you considered GraphQL and picked REST for subtle reasons, record it — otherwise someone will suggest GraphQL again in six months.
