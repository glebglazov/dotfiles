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
   done. List what the diff does that no item asked. Done when every asked
   item has a status and evidence, and every changed file is under an item or
   in the list of what no item asked.
3. **Plan the sections.** Read `~/.agents/docs/pages/core.md` in full. Answer
   first: did the work do what was asked, and what differs. Then one section
   per layer: what was asked against the result, as a table of asked items,
   each with the words of its source quoted, its status and `file:line`; each
   difference, with its reason; the evidence; what no item asked. Write 2–3
   prediction questions about what changed, the ones a reviewer must answer
   before a merge. Done when each
   section has one claim as its heading and one view from the core's Views,
   and each prediction question has the section that answers it.
4. **Write, check and deliver.** Do the core's steps in order, each to its own
   Done. Give the fact check the diff and the source of each asked item. The
   page ends with what is not done and the follow-ups, and Check yourself
   comes right before it. Done when the core's Deliver step is done.
