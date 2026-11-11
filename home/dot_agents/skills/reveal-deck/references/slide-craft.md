# Slide craft

reveal.js markup for the inside of one slide file. Every snippet goes inside
the slide's `<section>` or its `<style>` block.

## Position

The canvas is 1920×1080 with `center: false`, and reveal.js scales it to fit
the screen. Pixel positions on the canvas hold at every screen size:

```html
<h2 class="intro-title" style="position:absolute; left:120px; top:100px;">Title</h2>
```

`r-stack` puts its children on top of each other. With fragments, they show one
after another in the same place.

## Fragments

`class="fragment"` hides an element until the next click. Variants:
`fade-up`, `fade-out`, `highlight-red`, `grow`, and more. `data-fragment-index`
sets the order when it differs from the document order.

## SVG

Inline `<svg>` gives CSS and JS a handle on each shape. `class="fragment"` works
on `<g>`, `<path>` and other SVG elements, so a diagram can build one part per
click. `currentColor` in a stroke or fill follows the theme's text colour in
light and dark mode.

## Auto-animate

Give `data-auto-animate` to two consecutive `<section>`s, and give the matching
element the same `data-id` on both. reveal.js animates position, size and
colour from the first to the second. It works across two slide files, but only
the full deck shows it: a slide file alone has no neighbour.

## Speaker notes

`<aside class="notes">` inside the section. The presenter opens them with `S`.

## One slide's backdrop and transition

Attributes on the `<section>`:

- `data-background-color`, `data-background-image`, `data-background-video`,
  `data-background-iframe`
- `data-transition="zoom"` (or `fade`, `slide`, `convex`, `none`)

## A style for the whole screen while one slide shows

`data-state="<name>"` on the `<section>` adds class `<name>` to the document
root while the slide shows. Key the slide's CSS on it to reach the background,
controls and progress bar:

```html
<section data-state="intro-dark">…</section>
<style>
  .intro-dark .reveal-viewport { background: black; }
</style>
```

## Scoping without the prefix

`@scope (section.<slug>) { … }` limits rules to one section in current
browsers. The slug prefix stays the default, because it also works in old ones.

## Scripted motion

reveal.js events `slidechanged` and `fragmentshown` run your own JS, for
example GSAP or D3, when a slide or step shows. Put the script in `deck.js`,
because the deck does not run scripts from slide files.
