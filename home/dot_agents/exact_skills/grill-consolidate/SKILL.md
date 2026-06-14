---
name: grill-consolidate
description: Fold accumulated CONTEXT.<counter>.<uuid>.md glossary fragments into canonical CONTEXT.md files as a deliberate single-writer maintenance pass. Use when the user asks to consolidate, fold, merge, reconcile, clean up, or resolve concurrent context/glossary fragments produced by grill-with-docs.
---

# Grill Consolidate

Use this skill to merge colocated `CONTEXT.<counter>.<uuid>.md` fragments into their base `CONTEXT.md`.

This is a single-writer operation. Do not run it speculatively, automatically, or in parallel with another consolidation pass. If contested terms require a semantic decision, ask the user and wait.

## Find Contexts

Start at the repository root.

- If `CONTEXT-MAP.md` exists, read it and inspect each listed context path.
- If a root `CONTEXT.md` exists, inspect that context.
- Also search for colocated fragment files with `rg --files -g 'CONTEXT.*.md'`.
- A fragment belongs to the `CONTEXT.md` in the same directory.

If a directory has fragments but no `CONTEXT.md`, create a base `CONTEXT.md` only after at least one fragment will be folded into it.

## Read Inputs

For each context directory:

1. Read the base `CONTEXT.md`, if present.
2. Read every colocated fragment matching `CONTEXT.*.md`.
3. Parse each fragment filename as `CONTEXT.<counter>.<uuid>.md`.
   - `counter` is a numeric generation. Sort it numerically, not lexicographically.
   - `uuid` identifies the writer/session, but does not decide precedence.
   - Legacy `CONTEXT.<uuid>.md` fragments, if present, have no ordering metadata; treat same-term overlap involving them as contested.
4. Parse fragment ops:
   - `+ Term` adds a term.
   - `~ Term` redefines a term and should include `was:`.
   - `- Term` retires a term.
5. Treat `avoid:` and `under:` as optional metadata.

Do not silently ignore malformed ops. If the intended meaning is obvious, preserve it and mention the cleanup. If it is ambiguous, ask.

## Merge Rules

- Apply `+`, `~`, and `-` ops into the base glossary.
- A fragment op beats the base definition.
- Higher generations beat lower generations for the same term. A later generation means the author had the earlier generation available and is intentionally refining or overriding it.
- Two or more fragments in the same generation touching the same term are contested. Do not pick a winner without the user.
- A legacy unnumbered fragment touching the same term as any other fragment is contested.
- For `~ Term`, compare `was:` to the effective definition at that point in generation order. If the underlying meaning drifted materially, treat it as contested.
- File terms with a valid `under:` hint into that section.
- Put terms without a clear home into the best existing section when obvious; otherwise ask the user.
- Preserve the `CONTEXT.md` contract: it is a glossary only, not a spec or implementation notes file.

## Glossary Format

Keep base files in this shape:

```md
# {Context Name}

{One or two sentence description of what this context is and why it exists.}

## Language

**Order**:
One or two sentences defining the term.
_Avoid_: Purchase, transaction
```

Rules:

- Be opinionated: pick one canonical term and list rejected synonyms under `_Avoid_`.
- Keep definitions to one or two sentences.
- Define what the term is, not what it does.
- Include only project-specific domain language.
- Use subheadings under `## Language` only when natural clusters exist.

## Finish

After all conflicts are resolved:

1. Update the base `CONTEXT.md`.
2. Delete only the fragments that were folded in.
3. Show the user the changed files and any terms that were added, redefined, retired, or manually resolved.

Never delete a fragment that was not fully applied.
