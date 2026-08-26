# Read a commit's content in revision buffers, never by checking it out

The Neovim review plugin reviews a stack one commit at a time, which means
showing each file as it was in the Current Commit. The obvious way — checking
the commit out — is rejected: it is a global side effect for a local need. It
detaches HEAD, reloads every buffer, forces LSP and treesitter to re-index the
whole tree on each switch, disturbs watchers and dev servers, and refuses to
move at all when the working tree is dirty. Instead, a Revision Buffer opens the
file through `FugitiveFind('<sha>:<path>')`: read-only, exact commit content,
working tree untouched.

## Consequences

Gitsigns already parses commits out of `fugitive://` paths and attaches to those
buffers, so a buffer-local `change_base('<sha>^')` makes the signs show that
commit's own hunks. Hunk navigation and per-hunk commenting fall out of that for
free, rather than needing a hand-rolled diff renderer.

The cost is that a Revision Buffer is not a file on disk, so no language server
attaches: no go-to-definition and no diagnostics while reviewing. This was
accepted on the grounds that reviewing is reading. A separate keybinding jumps
from a Revision Buffer to the same path and line in the real working tree for
the times a fix should happen immediately.

## Considered options

Checking out a scratch `git worktree` per commit was the third option: real
files on disk, main tree untouched, and LSP does attach. It was rejected for now
because a scratch tree has no installed dependencies, so the language server it
gains is usually half-broken anyway. Both approaches sit behind the same seam —
"give me a buffer for `(sha, path)`" — so this can be revisited without touching
session state, Comment anchoring, or the export.

## Amendment — scratch worktrees are dropped, not deferred

This decision left the language-server cost open on the grounds that a scratch
`git worktree` could be swapped in behind the same seam if reading without one
proved too painful. It did prove painful — enough that the reader asked for a way
back after leaving a Revision Buffer to investigate — but the answer is not the
worktree.

The Investigation Tab opens the file's working-tree copy in a separate tab, where
a language server attaches to a real file in a real checkout **with dependencies
installed**. The scratch worktree was rejected here for having no dependencies and
therefore a half-broken language server; the working tree has a whole one. The
rejected option is now strictly dominated, so it is dropped as a direction rather
than left on the roadmap.

What remains unavailable is a language server over the file *as it stood at the
commit*, which matters only when the commit and the working tree have diverged
enough that the definitions differ. The `buffers` seam stays as it is — it costs
nothing to keep and it is what makes this reversible if that case turns out to
bite.
