---
name: mermaid
description: >-
  Mermaid diagrams — render one and show it as a picture. Use when a ```mermaid
  block or .mmd/.mermaid file is in play, when you write a diagram for the user
  to look at, or when the user asks to view, open or export one.
---

# Mermaid

A mermaid diagram in chat is text the user has to read as text. `mmd-show`
renders it with `mmdc` and puts the picture on their screen.

Render every mermaid diagram you produce or read, in the same turn it comes up.

## Show it

```sh
mmd-show diagram.mmd                       # a file
cat file.md | mmd-show -                   # stdin; ```mermaid fences are stripped
mmd-show - <<'MMD'                         # a diagram you just wrote
graph TD
  A[Start] --> B{Ok?}
MMD
```

Extra arguments go straight to `mmdc`: `mmd-show diagram.mmd --theme default`
for light-background output, `--width 2400` for a wide graph.

It prints the PNG path first, then picks a route by where its stdout goes:

- **Drawn in place** when stdout is the user's own terminal and that terminal
  speaks the kitty graphics protocol — what happens when the user runs the
  command by hand.
- **A viewer pane** when stdout is yours, not a screen — every call you make
  from a tool. The diagram lands in a tmux pane to the right of the pane running
  you, one viewer per caller, reused for each diagram after the first. The
  command reports the pane id it drew in.
- **The desktop viewer** outside tmux with no graphics protocol.

So tell the user where the diagram is — the pane, and the path as their handle
for reopening it. The pane holds a shell under the image, so the user closes
it with `exit` — leave it up until they do.

## Keep it

`mmd-show` writes to a temp directory. For an artifact that survives, call
`mmdc` yourself and pick the format by extension (`.svg`, `.pdf`, `.png`):

```sh
export PUPPETEER_EXECUTABLE_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
mmdc -i diagram.mmd -o docs/diagram.svg
```

`mmdc` drives headless Chrome through puppeteer and mise installs it without a
bundled browser, so that export is what points it at the installed Chrome.
`mmd-show` sets it for you.
