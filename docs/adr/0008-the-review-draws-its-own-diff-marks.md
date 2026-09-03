# The review draws its own Diff Marks

The signs a reader read a Review Session by came from gitsigns: the session set
its base globally, turned its signs and its inline deleted lines on, and each
Revision Buffer was re-based to the span's base on a retry loop. Whole classes
of file in the Changeset came up blank, and every one of the reasons was silent —
gitsigns does not attach to untracked files at all (`attach_to_untracked` is off
by default), it refuses files over its length limit and files with `-diff` set,
it publishes the buffer variable the retry loop waited on *before* it decides
whether to attach, and a Revision Buffer that misses its base change is diffed
against the very commit it is showing, which yields no signs whatsoever. A
plugin that re-derives the diff per buffer has to have attached to that buffer
first, and the review's own walk reaches buffers it never will.

The review therefore draws **Diff Marks** itself, from the single
`git diff --unified=0` run the Changeset is already built from: signs on the
lines each hunk left behind, and the removed text as virtual lines where it was
taken from. Nothing attaches, nothing is asked for a base, and no file is
exempt — an untracked file, a file the span deleted, a file of any length are
all marked from the same output the reader is walking. It also ends the
session's reach into editor-wide state: the marks are extmarks in a namespace of
the review's own, so ending a session cannot leave a global option changed
behind it, which the old teardown existed to undo.

## Consequences

The marks are a reading of the span, not a live diff. A Revision Buffer cannot
change, so it is drawn once; a file on disk can, so its own diff is asked again
on write and on every entry into the buffer. What is deliberately *not* rebuilt
is a per-keystroke pipeline — debounced diffing of an unsaved buffer is the job
description of the plugin this replaces, and re-earning it would trade the whole
reason for the change back again.

`preview_hunk` and gitsigns' `]h`/`[h` are no longer part of a session. The
review has its own walk over the same hunks, and the removed text is on screen
rather than in a float. gitsigns keeps its own keys and its own life outside a
review.
