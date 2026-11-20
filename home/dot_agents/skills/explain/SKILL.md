---
name: explain
description: "Use when writing an explainer: an HTML page, delivered through Lavish, that explains how a system, process or change works, or how alternatives differ."
---

# explain

An **explainer** is one HTML page that gives the reader a correct model of how
something works. Each point on the page uses the **view** that shows it best
(see [Views](#views)), and every view works on a phone.

## Steps

1. **Learn the subject.** Read the code, docs and data the page is about, and
   the project's `GLOSSARY.md` or `CONTEXT.md`. Collect real names, real
   numbers and real UI from the subject. Done when you can tell the reader's
   question and its answer in two sentences.
2. **Plan the sections.** Start from what the reader sees: the real UI, output,
   command or status. Then go deeper. Each section adds one layer, so the
   reader can stop after any section and still have a correct model. Done when
   each section has one point and one view from [Views](#views).
3. **Write the page.** Load the `lavish` skill. Its CLI gives the design
   direction and the location of the file. Open the playbook of each view you
   use (`diagram`, `comparison`, `table`, `code`). Where a playbook differs
   from this skill, follow this skill. Make every part
   [responsive](#responsive). Done when the file has all the sections.
4. **Check the layout.** Run `<this skill's directory>/scripts/check-layout
   <file.html>`. It renders the page at 390 px and 1280 px, and prints each
   overflow, squeezed text column and small SVG label. Fix each problem. Done
   when it exits 0.
5. **Deliver.** Open the page through the `lavish` skill.

## Views

| When the point is | Use |
|---|---|
| The terms the page uses a lot | A glossary table at the top: term, what it is, unit (tokens, KB, ms…) |
| One process, events in order | A sequence diagram: one lane per participant, each arrow labelled with the message and its data |
| How components relate | A relation diagram: who calls whom, why, and what data passes, on each arrow |
| The lifecycle of one thing | A state diagram: states, and each transition labelled with its event |
| A race or a timing problem | A timeline with one lane per actor, and the bad interleaving marked |
| What goes wrong | The failure path next to the happy path, in the same diagram |
| How it works in practice | A real-world scenario, worked step by step with real numbers from the subject |
| A change | Before and after side by side, the same scenario on each side, each with its diagram |
| A UI or a layout | A mockup of the real UI in the product's own design system, with its real labels and arrangement |
| Alternatives | A table with one row per option, and a legend that uses colour and shape for the differences |
| Logic | Pseudocode |
| Code that changes | A diff in the shape of the change, as the `show-me` skill does: code, call tree, file tree, component tree or state. Show the whole block when most of it is new |

Use only the views that the points need.

## Responsive

The page must work at 390 px wide.

- **Wide diagram.** Draw a second, vertical version for narrow screens and
  switch between the two with a media query. Or put the diagram in its own
  `overflow-x: auto` frame with a `min-width` that keeps its labels at 11 px or
  more. A diagram that only scales down makes its labels too small to read.
- **Table.** When its columns get narrower than about 64 px at 390 px, put it
  in an `overflow-x: auto` frame with a `min-width`, or show each row as a
  card on narrow screens.
- **Step lists and grids.** Put each item's content in one wrapper element.
  DaisyUI `steps` puts each direct child of a step in its own grid cell, so
  bare inline `<code>` goes into the 40 px number column.
