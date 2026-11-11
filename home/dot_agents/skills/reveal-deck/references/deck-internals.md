# Deck internals

How the deck is built, where the deck-wide settings live, and the gotchas
behind a slide that renders differently alone than in the deck.

## Two modes of deck.js

Every HTML file in the deck loads `reveal.css`, `theme.css`, `reveal.js`, the
notes plugin and `deck.js`. Then `deck.js` takes one of two paths:

- **Deck mode** (`index.html`, which has `.reveal .slides`): it fetches
  `slides.txt`, then each slide file in that order. From each one it copies the
  `<style>` blocks in `<head>` and the first `<section>` in `<body>`. Links and
  scripts in slide files are ignored. `DOMParser` runs no scripts, so the copy
  of `deck.js` inside a slide file stays inert.
- **Alone mode** (a slide file): it wraps every `<section>` in `<body>` into a
  new `.reveal .slides` and starts reveal.js. Only the sections move, so
  anything a host such as Lavish injects into `<body>` stays where it is.

Both modes call `Reveal.initialize(REVEAL_CONFIG)`, so one object in `deck.js`
sets the canvas, plugins and options for the deck and for each slide alone.

## Where to change what

| To change | Edit |
|---|---|
| Colours, fonts, shared styles for this deck | `<dir>/theme.css` |
| Canvas size, transitions, plugins for this deck | `REVEAL_CONFIG` in `<dir>/deck.js` |
| Defaults for every new deck | this skill's `assets/template/` |
| The command itself | this skill's `scripts/reveal-deck` (`~/.local/bin/reveal-deck` is a symlink to it) |

This skill's files are rendered by chezmoi: run `chezmoi source-path` on a file
to find the copy to edit, then `chezmoi apply` it.

A new plugin loads from a `<script defer>` placed before `deck.js` in
`index.html`, in the template's `slide.html` and in every existing slide file.

`theme.css` follows the OS light or dark setting through CSS variables under
`@media (prefers-color-scheme: dark)`. Keep that pattern when adding colours.

## Gotchas

- **Background stays white.** reveal.js gives `<body>` the class
  `.reveal-viewport` with its own background. A theme rule must name
  `.reveal-viewport` as well as `body`.
- **Deck is empty over `file://`.** `fetch` needs HTTP. Use `reveal-deck serve`.
- **Slide differs alone and in the deck:**
  - more than one `<section>` in the file: the deck takes the first, alone mode
    shows all;
  - a class without the slug prefix: in the deck, another slide's rule with the
    same class name wins;
  - a style in a `<link>` or a `<script>` in the slide file: alone mode loads
    it, deck mode drops it. Move it to `theme.css` or `deck.js`.
- **Lavish shows no styles.** Lavish serves the file's own folder. Assets must
  sit beside the slide file and use relative paths without a leading `/`. The
  flat deck folder already meets this.
- **No network, no deck.** reveal.js loads from the jsDelivr CDN as
  `reveal.js@5`, so a new 5.x release reaches every deck on its next load.
