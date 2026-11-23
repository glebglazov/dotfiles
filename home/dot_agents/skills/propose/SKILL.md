---
name: propose
description: "Use when writing a planning page, or when the user asks how to change a system or reach a goal and the plan needs their decisions. An HTML page delivered through Lavish, with the decisions the user answers on it. Start it before you read the code: its first step does the research."
---

# propose

A **planning page** is a page that shows how to change something and asks the
reader its [decisions](#decisions). This skill finds the facts, the plan and
the decisions. The core, `~/.agents/docs/pages/core.md`, defines a page and
has the steps that write, check and deliver it.

Understand first, then decide: explain → propose → the work → debrief. The
reader gets a correct model of the system from an explainer, and decides on a
planning page that builds on it. A decision made on a wrong model is hard to
undo, and deciding while the model is still forming costs attention.

## Steps

1. **Learn the subject and the goal.** Read the code, docs and data the change
   touches, and the project's `GLOSSARY.md` or `CONTEXT.md`. Collect real
   names, real numbers and real UI. The facts come from the code as it is;
   label each part of the page that does not exist yet as a proposal. Write
   down who the reader is and what they already know; when the user does not
   say, the reader is the user. Find the explainer of the same subject in this
   conversation or in the Lavish folder. When there is one, link to it, use
   its glossary, and explain again only what the change needs. When there is
   none and you cannot tell that the reader knows the system, offer an
   explainer first in a line at the top of the page. Done when you can tell
   the reader's question and its answer in two sentences.
2. **Plan the sections.** Read `~/.agents/docs/pages/core.md` in full. Start
   from what the reader sees today: the real UI, output, command or status.
   Then show what the change does to it, one layer per section. Write 2–3
   prediction questions, about the change only. List the
   [decisions](#decisions). Done when each section has one claim as its
   heading and one view from the core's Views, each prediction question has
   the section that answers it, and each decision names the section after
   which the reader has its context.
3. **Write, check and deliver.** Do the core's steps in order, each to its own
   Done. Check yourself comes before `#decisions`. Done when the core's
   Deliver step is done.

## Decisions

A **decision** is a question to the user that the plan depends on and that the
code, the docs and the user's words do not settle. The reader sees each
decision while its context is fresh, and commits all of them at the end, with
the whole model in view.

- **Top.** After the answer, say how many decisions need the user, and link
  to each.
- **Inline.** Put each decision in a callout right after the section that
  gives its context. Give it a stable ID (D1, D2…), the question, the options,
  what each option changes, and your recommendation with its reason. Its
  radios keep a local choice. Its "Queue answer" button queues that one
  answer with `data-lavish-question` set to the ID, so a second queue of the
  same decision replaces the first. A queued answer waits in Lavish until the
  reader presses Send to Agent.
- **End.** A `<section id="decisions">` after `#check` lists every decision
  with its state (open, chosen, queued, decided), says how the decisions
  affect each other, and lets the reader change and queue each one again.
  "Accept all recommendations" queues your recommendation for each decision
  still open. Leave each choice empty until the reader picks it.
- **Answers.** When the answers arrive, account for every decision ID: act
  on it, or name it as still open. The page keeps a choice only until it
  reloads, so write each answer into the page: its choice set, its state
  "decided", and its controls disabled. The top then lists the decided ones
  apart from the open ones.

(Interruption cost: Altmann & Trafton 2002; contiguity: Mayer 2020; adjunct
questions after the text: Hamaker 1986; anchoring on early and default
choices: Tversky & Kahneman 1974, Johnson & Goldstein 2003)
