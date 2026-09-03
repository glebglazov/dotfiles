---
name: mermaid
description: >-
  Mermaid diagrams — render one and draw it inline in the terminal. Use when a
  ```mermaid block or .mmd/.mermaid file is in play, when you write a diagram
  for the user to look at, or when the user asks to view, open or export one.
---

# Mermaid

A mermaid diagram in chat is text the user has to read as text. Render it and
the terminal draws the picture instead: `mmd-show` renders with `mmdc` and
draws the PNG in place over the kitty graphics protocol (tmux passthrough is
on, so it works inside tmux).

Render every mermaid diagram you produce or read, in the same turn it comes up.

## Draw it

```sh
mmd-show diagram.mmd                       # a file
cat file.md | mmd-show -                   # stdin; ```mermaid fences are stripped
mmd-show - <<'MMD'                         # a diagram you just wrote
graph TD
  A[Start] --> B{Ok?}
MMD
```

It prints the PNG path, then draws it. Give the user the path too — that is
their handle for reopening or sharing the image.

Extra arguments go straight to `mmdc`: `mmd-show diagram.mmd --theme default`
for light-background output, `--width 2400` for a wide graph.

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
