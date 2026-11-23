# Pages: the core

A **page** is one HTML page, delivered through Lavish, that gives the reader a
correct model of something. Each verb skill (`explain`, `propose`, `debrief`)
finds its facts and plans its sections by its own steps. Then it writes,
checks and delivers the page by the steps here. Each point on a page uses the
**view** that shows it best (see [Views](#views)) and follows the
[design rules](#design-rules), and every view works on a phone.

A **prediction question** is a question that a reader with the correct model
answers from the page, such as "what happens when the upload fails?". It has
its answer and two wrong options, each a real way to misread the subject, and
it names the section that teaches it. The verb skill says how many a page has.
The page shows them in [Check yourself](#design-rules), and the
[reader test](#steps) asks them.

## Steps

Start these after the verb skill's plan: each section has one claim as its
heading and one view, and each prediction question has its section.

1. **Write the page.** Load the `lavish` skill. Its CLI gives the design
   direction and the location of the file. Open the playbook of each view you
   use (`diagram`, `comparison`, `table`, `code`), and `input` when the page
   has decisions. Where a playbook differs from this core or the verb skill,
   follow the core and the verb skill. Apply every
   [design rule](#design-rules), and make every part
   [responsive](#responsive). Done when the file has all the sections.
2. **Check the facts.** Start a subagent with no other context. Give it the
   page and the paths of its sources. It marks each claim, name and number on
   the page as supported, unsupported or wrong, and cites the source line.
   Fix or remove each claim that is not supported. Label each number that is
   an example and not real data as illustrative, on the page. Done when the
   subagent finds no unsupported or wrong claim.
3. **Test the reader.** Start a second subagent with no other context. Give it
   a copy of the page without its `#check` section, and the prediction
   questions without their answers. Compare its answers with yours. For each
   wrong answer, fix the section that must teach it, and test again. Done when
   it answers every question correctly. After two failed rounds, tell the user
   which questions still fail.
4. **Check the layout.** Run `~/.agents/docs/pages/check-layout <file.html>`.
   It renders the page at 390 px and 1280 px, in the light and the dark
   scheme, and prints each overflow, squeezed text column, small SVG label and
   text under WCAG contrast. Fix each problem. Exit status 2 means a render
   could not load, not a problem in the page: run it again. Done when it exits
   0.
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
| A UI or a layout | A mockup of the real UI in the product's own design system, with its real labels and arrangement. Mark its root with `data-mockup`: the contrast check skips it, because its colours are the product's |
| Alternatives | A table with one row per option. Mark each difference in its cell with a symbol and a word, and use colour as a second signal |
| Quantities to compare | Bars or dots on one shared baseline, with each value labelled on its bar or dot |
| Logic | Pseudocode |
| Code that changes | A diff in the shape of the change, as the `show-me:show-me` skill does: code, call tree, file tree, component tree or state. Show the whole block when most of it is new |

Use only the views that the points need.

## Design rules

These rules come from research on how people learn from text and pictures. The
name in brackets is the effect and its source.

- **Answer first.** Open with the reader's question and its two-sentence
  answer, before any detail. (Advance organizer: Ausubel 1960; Bransford &
  Johnson 1972)
- **Headings are claims.** Write each section heading as a sentence that states
  its point: "The cache is written only after the upload succeeds", not
  "Caching". (Assertion-evidence headlines: Alley et al. 2006)
- **Example before rule.** Show the concrete case with real data first. Then
  name the general rule. (Worked examples: Sweller & Cooper 1985; concreteness
  fading: Fyfe et al. 2014)
- **Words where they apply.** Label each part of a diagram on the part or next
  to it. Put the text that explains a view beside the view. Use a direct label
  in place of a legend where the space allows it. (Split attention: Chandler &
  Sweller 1991; spatial contiguity: Mayer 2020)
- **Mark the point.** In each view, highlight the parts that its section is
  about, and mute the rest. (Signaling: Mayer 2020)
- **Only what teaches.** Keep only the images, stories and diagram parts that
  the point needs. (Coherence, seductive details: Harp & Mayer 1998)
- **Few chunks per view.** Keep a diagram to about 4–7 groups. When it has
  more, group nodes into labelled boxes, or split it into two views. (Working
  memory: Cowan 2001)
- **One look across views.** Give each participant, state or option the same
  name, colour and position in every view on the page. When two views show the
  same thing, say how their parts map to each other. (Multiple representations:
  Ainsworth 2006)
- **Align what you compare.** Show compared things side by side, on the same
  scale and in the same order, with the differences marked. (Contrasting
  cases: Alfieri et al. 2013)
- **Numbers by position or length.** Compare quantities with bars or dots on a
  shared baseline. Use a table when the reader needs exact values, and a chart
  when the reader needs the pattern. (Perceptual accuracy: Cleveland & McGill
  1984; cognitive fit: Vessey 1991)
- **Steps, not motion.** Show a process as static, numbered frames. (Animation:
  Tversky et al. 2002)
- **Fit the reader's level.** Give a new reader every step. For an expert,
  keep the main path short and put derivations and edge cases in a closed
  `<details>`. (Expertise reversal: Kalyuga et al. 2003)
- **Colour plus a second signal.** Pair each colour with a shape, a label or a
  pattern. Text keeps the base text colour: a callout or badge shows its kind
  with a border, an icon or a light tint. DaisyUI `alert-soft` and
  `badge-soft` colour their text, which is unreadable in the light scheme, so
  set their `color` to `var(--color-base-content)`. (WCAG 2.2, 1.4.1 Use of
  Color and 1.4.3 Contrast)
- **Check yourself.** Put the prediction questions in a
  `<section id="check">` headed "Check yourself", with one line under the
  heading: make sure you understand it well enough before you decide. Each
  question is multiple choice: the reader picks first, and only then sees if
  the pick is right, why, and a link to the section that teaches it. The page
  gives this feedback itself, with no agent. A wrong pick offers to queue
  "section N did not teach this" with `queueKey` `check-Q1`, `check-Q2`…, so
  the reader is a second reader test. Write each question, its options, the
  right answer and the feedback as HTML inside `#check`, for example as data
  attributes on the options; a script may show and hide them, but it holds
  none of them. The reader test removes `#check`, and an answer left outside
  it gives the test away. The check is optional and blocks nothing. The verb
  skill says where it goes on the page. (Retrieval practice: Roediger &
  Karpicke 2006; feedback after the attempt: Butler & Roediger 2008; illusion
  of knowing when the answer is in view: Koriat & Bjork 2005)

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
