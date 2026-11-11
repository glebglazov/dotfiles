---
name: reveal-deck
description: "Use when making slides, a deck or a presentation: a reveal.js deck with one HTML file per slide, built with the `reveal-deck` command."
---

# reveal-deck

A **deck** is a flat folder. Each **slide file** in it is a complete HTML page
with one `<section>`. `index.html` merges the slide files in the order of
`slides.txt`. A slide file opened alone renders as a one-slide deck with the
same settings and theme, so a browser or Lavish shows it as the deck does.
`reveal-deck --help` lists the files and the job of each.

## Steps

1. **Make the deck.** Run `reveal-deck new <dir> "<title>"`. Done when
   `<dir>/slides.txt` lists the title slide.
2. **Plan the story.** Write the slide list first: one idea per slide, opening
   with the point and closing with the decision or next action. Done when each
   idea has a short name.
3. **Add the slides.** Run `reveal-deck slide <dir> "<name>"` once per slide, in
   order. The command makes the slide file, fills in its class prefix and
   appends it to `slides.txt`, so it is the only way slide files come into
   being. To reorder, move lines in `slides.txt`. Done when `slides.txt` lists
   every planned slide.
4. **Write each slide.** Edit its `<style>` block and its `<section>`:
   - The canvas is 1920×1080 and stays put. Place elements with
     `position: absolute` in canvas pixels.
   - Start every class with the slide's slug, as the template's
     `.<slug>-title` does. The deck merges every slide's `<style>` into one
     page, so a rule without the prefix reaches other slides too.
   - Keep one `<section>` per file.
   - Put styles shared by several slides in `theme.css`.

   For fragments, SVG, auto-animate, speaker notes, backgrounds or a style for
   one slide only, read [slide-craft.md](references/slide-craft.md).
   Done when every slide in `slides.txt` holds its content.
5. **Check it renders.** Start `reveal-deck serve <dir> [port]` in the
   background, then load the deck and each slide file in a headless browser.
   Done when `Reveal.getTotalSlides()` equals the number of slide lines in
   `slides.txt`, every slide file loads alone, and the console shows no errors.
6. **Hand it over.** Open `http://localhost:<port>/` in the browser. For
   annotated review of a slide, open its slide file with the `lavish` skill.

To change the look or the reveal settings of the whole deck, or when a slide
renders differently alone than in the deck, read
[deck-internals.md](references/deck-internals.md).
