---
name: explain
description: "Use when writing an explainer, or when the user asks to explain or walk through how a system or process works, or how alternatives differ, and the answer needs diagrams or a page. An HTML page delivered through Lavish. Start it before you read the code: its first step does the research."
---

# explain

An **explainer** is a page that gives the reader a correct model of how
something works. This skill finds the facts and plans the sections. The core,
`~/.agents/docs/pages/core.md`, defines a page and has the steps that write,
check and deliver it. The `propose` skill plans a change on a page that builds
on the explainer, and the `debrief` skill shows what a change did.

## Steps

1. **Learn the subject.** Read the code, docs and data the page is about, and
   the project's `GLOSSARY.md` or `CONTEXT.md`. Collect real names, real
   numbers and real UI from the subject. Write down who the reader is and what
   they already know; when the user does not say, the reader is the user.
   Done when you can tell the reader's question and its answer in two
   sentences.
2. **Plan the sections.** Read `~/.agents/docs/pages/core.md` in full. Start
   from what the reader sees: the real UI, output, command or status. Then go
   deeper. Each section adds one layer, so the reader can stop after any
   section and still have a correct model. Write one prediction question for
   each section. Done when each section has one claim as its heading and one
   view from the core's Views, and each prediction question has the section
   that answers it.
3. **Write, check and deliver.** Do the core's steps in order, each to its own
   Done. Check yourself is the last section, and a line after it offers to
   propose a change from this page. Done when the core's Deliver step is done.
