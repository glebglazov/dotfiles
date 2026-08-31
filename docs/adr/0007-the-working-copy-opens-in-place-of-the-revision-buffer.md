# The Working Copy opens in place of the Revision Buffer

Leaving the review to read a whole file opened an Investigation Tab, on a key of
its own. The tab existed because it made the trip free: the review's windows, its
cursor and its Changeset window were never touched, so coming back needed nothing
restored. It cost two keys — `<LEADER>rg` out and back, `<LEADER>rr` home — and
the reader used neither, because a second tab is not where they want the file.

The **Working Copy therefore opens in place**, in the review's own window, on the
same key that goes home: `<LEADER>rr` on a Review Surface opens the file being
read, and `<LEADER>rr` anywhere else returns to the **Review Position**. The
Investigation Tab is removed.

This works because the return trip no longer depends on anything having survived.
The Review Position is session facts — the targeted span, the Revision Buffer's
commit and path, the cursor's line and column — not a window, a buffer or a tab,
so `gd` out of the opened file, a closed window, or fugitive wiping the blob
buffer on the way out (it sets `bufhidden=delete`) all cost nothing. The Review
Tab was already reconstructible by
[ADR-0005](0005-the-review-tab-is-rebuilt-not-defended.md); this decision retires
that ADR's closing line, which kept the Investigation Tab for its language server
and its free movement. A file opened in place has both.

The rejected alternative was keeping the tab and binding it to `<LEADER>rr` as
well, so one key crossed between two tabs. It keeps a free return trip, but the
tab is the thing the reader does not want: the file arrives away from the
Changeset window, and every trip out costs a tab switch that has to be undone.
Once the return trip is cheap to rebuild, the tab buys nothing that the Review
Position does not.

## Consequences

The cursor is carried into the Working Copy verbatim. Commit content and the file
on disk are rarely the same lines, and mapping through the diff is the dishonesty
[ADR-0006](0006-a-rewrite-rebinds-comments-to-head-rather-than-ending-the-review.md)
already refuses for comments — no mapping is right often enough to be trusted. A
drift the reader can see is better than being silently one hunk off.

**Review Surface** becomes one predicate, and everything that must tell the
review from the rest of the editor asks it: which way the toggle goes, which
colour the Review Badge takes, and which buffers carry `]e`, `]f` and `<Tab>`. A
buffer is a Review Surface when it is a Revision Buffer, the Changeset window,
or — while the Targeted Range ends at the Uncommitted Tip — a file on disk the
Changeset holds.

`buffers.member` narrows to that predicate. It counted every working-tree file in
the Changeset, which gave the walk and the comment key to a file opened while
commits were targeted — a file whose content is HEAD, whose line numbers are not
the commit's, and which `render.buffer` already refuses to trust for exactly that
reason. ADR-0005 observed the reader landing such files in the review's window by
habit and gaining the walk there; that is what is given up. In exchange a Working
Copy is the plain editor, which is what it is opened to be.

The Review Badge takes two colours rather than one, and this is the only visible
answer to "which side am I on" — lit on a Review Surface, muted elsewhere. It is
chosen per window from that window's own buffer, since the statusline is
per-window here, so no `g:actual_curwin` is needed.

A Targeted Range ending at the Uncommitted Tip has no Working Copy to open: it is
already read from the files on disk (ADR-0004). The key goes home there, landing
on the current Changeset entry — as it does on a Revision Buffer whose file is not
in the working tree. A key bound to "the other side of the review" never does
nothing.

The Review Position is not persisted. After a restart there is nothing to return
to, and `persist.restore` already lays the reading position out from the
Changeset, which is where the fallback lands anyway: a Range Refresh that moved
the target while the reader was in the Working Copy makes the remembered position
point into a diff no longer on screen, so it is dropped for the current entry's
hunk.
