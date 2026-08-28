# The Review Tab is rebuilt, not defended

Leaving the review to read a whole file opened an Investigation Tab, and the way
back was the same key pressed in that tab — which meant the review's home was
never a thing in its own right, only "the tab I was in when I last pressed
`<LEADER>rg`". In practice the reader does not use that key at all: they reach
for the editor's file search out of habit, which lands a working-tree file in the
review's own window, and no key anywhere means "take me back to the review".

The review therefore gets a **Review Tab** it knows from the moment a session
starts or is restored, reachable from anywhere in the editor on `<LEADER>rr`, and
**rebuilt from session state when it is gone** — one window holding the current
Changeset entry's file with the cursor on that hunk, plus the changeset window.
Nothing defends it.

The rejected alternative was to defend it: notice a non-review file arriving in
the Review Tab and relocate it to the Investigation Tab. It fights the reader —
it moves the cursor somewhere they did not ask for — and it cannot distinguish a
file opened to investigate from a file opened to go and work on. Once the tab is
reconstructible, there is nothing left to defend: scattering the review is a
non-event, and a habit that cannot be trained out of the reader does not need to
be.

## Consequences

Tab ids do not survive quitting nvim, so a restored session adopts the tab
`persist.restore` runs in — the tab whose signs it dressed and whose quickfix
list it filled. That tab is the review's in every respect but the name.

The Investigation Tab keeps its purpose (a language server and free movement
across files) but stops being the only route home, and returning to the review no
longer depends on the Review Tab having survived.
