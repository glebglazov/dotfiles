---
name: debrief
description: "Use when writing a debrief, or when the user asks what was done in a commit, branch or session, and why, or whether the work matches what was asked. An HTML page delivered through Lavish, before a review or a merge. Start it before you read the code: its first step does the research."
---

# debrief

A **debrief** is a page that shows what was done, why, and the evidence,
compared with **what was asked**: the source the work answers to. That is a
planning page and its decided answers, a request in chat ("implement X"), or,
for work with neither, its commit messages and PR body. This skill finds what
was asked and the evidence. The core, `~/.agents/docs/pages/core.md`, defines
a page and has the steps that write, check and deliver it.

Write the debrief in English so reviewers can read it without the original
conversation. Translate any conversation excerpts you include and label
translated quotations. Preserve code, commands and identifiers exactly.

## Steps

1. **Find what was asked.** Look in this order, and use every source that
   exists: the planning page of this work, in this conversation or in the
   Lavish folder, with its decided answers; the user's request in this
   conversation; the commit messages and the PR body. Split it into **asked
   items**: each decision, requirement and claim, with the ID it has (D1…) or
   a new one (A1…), and its source. Done when every asked item has an ID and
   a source.
2. **Collect the evidence.** Read the whole diff of the work and the
   project's `GLOSSARY.md` or `CONTEXT.md`. Find the tests that ran in this
   conversation and their output; when none ran, run the tests that cover the
   change, and say on the page which ran. For each asked item, write what the
   code does now, with `file:line`, and its status: done, done differently
   (with the reason, from the commit, the conversation or the code), or not
   done. List what the diff does that no item asked. From the repository,
   run `scripts/merge-signals` from this skill's directory (`--base <ref>`
   when the work does not merge into the default branch), and make the
   [merge assessment](#merge-assessment) of the change. Done when every
   asked item has a status and evidence, every changed file is under an item
   or in the list of what no item asked, and the merge assessment has every
   axis and the verdict.
3. **Plan the sections.** Read `~/.agents/docs/pages/core.md` in full. Answer
   first: did the work do what was asked, and what differs. Then one section
   per layer: what was asked against the result, as a table of asked items,
   each with the words of its source quoted, its status and `file:line`; each
   difference, with its reason; the evidence; what no item asked; the options
   not taken, and why; the glossary and ADR changes; how to roll the work
   back, and what does not come back; whether the change is rather safe to
   merge: the merge assessment, with a table of every merge signal and axis,
   each marked **measured** (from the script) or **judged** (from your
   reading). Error detection goes in that table as a judged row: would a
   failure in production be noticed, and does the diff swallow an error. When
   the work is not the user's own, give the signals and the axes, and leave
   out the verdict. Write 2–3
   prediction questions about what changed, the ones a reviewer must answer
   before a merge. Done when each
   section has one claim as its heading and one view from the core's Views,
   and each prediction question has the section that answers it.
4. **Write, check and deliver.** Do the core's steps in order, each to its own
   Done. Give the fact check the diff and the source of each asked item. The
   page ends with what is not done and the follow-ups, and Check yourself
   comes right before it. Done when the core's Deliver step is done.

## Merge assessment

The **merge assessment** says whether the change is rather safe to merge. The
change is the commits from the merge base with the default branch to `HEAD`:
what becomes the PR, whether or not the PR exists yet. Uncommitted work is not
part of it. It has six axes and a verdict. Fill each axis from the **merge signals**, the JSON of
`scripts/merge-signals`, first, and judge only what the signals cannot give.

- 🚪 **Door:** `one-way` or `two-way`. You can walk back through a two-way
  door, but not a one-way door. Destructive actions and hard-to-reverse
  decisions are one-way.
- 💥 **Blast radius:** one or two words for the scope of the impact, such as
  layout, consumers, deploy, data. Consider every way the change reaches
  users and other code. The diff size informs it, and is never red by
  itself.
- 🔒 **Security:** `none`, or what the change touches: authentication,
  secrets, personal data, permissions. `auth`, `secrets` and `payments`
  paths in the signals go here.
- 🔬 **Verification:** `verified` when evidence covers each changed
  behaviour: a screenshot for a visual change, test or command output for
  the rest. Otherwise name the gap: a behaviour with no evidence, a failing
  or pending CI check, or the changed lines the coverage report shows as
  uncovered. A test that should cover a behaviour and did not run is a gap.
  With checks `no-pr` or `none`, the evidence alone decides.
- ⚠️ **High-risk item:** only when the change touches one, such as a change
  to a UX flow, a migration or the connect path. Each other `sensitive` path
  in the signals is one, unless you name why it is not.
- ↩️ **Reversible:** when a revert undoes all of the change. Otherwise, how
  to undo it, and what does not come back.

The verdict is a gate, not an average: one red input outweighs every green
one.

```text
reasons = each red axis
        + each asked item "not done", or "done differently" with no approval
          from the human
if no reasons  → ✅ rather safe
else           → 👀 look first: <the first reason, in a few words>
```
