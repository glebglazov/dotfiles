# A Comment is counted on the commit that changed its lines

The Commit Switcher put a comment count on almost every row. The cause was not
the count but the filing: a Comment is filed under the Targeted Range it was
written against, a review at rest targets the whole Review Range, and
`state.span_holds` counted a Comment on every member of its span. So a review
read at rest — which is how a review is read — filed every Comment under
`oldest..newest` and then reported each one on every row. A column that says the
same thing about every row says nothing.

A Comment is therefore counted on its **Owning Commit**: the one member of its
span that changed the lines it points at, found by blaming those lines at the
span's newest member. A Comment with no such member is an **Unowned Comment**,
reachable from the Comment Picker alone; the Switcher's title carries only how
many of them there are.

## Consequences

This recovers per-commit attribution inside a Targeted Range, which
[ADR-0003](0003-the-changeset-is-a-contiguous-range-read-as-one-diff.md)
accepted the loss of. That ADR's decision is untouched: the Changeset is still
one merged `git diff` of the whole span, and nothing in the buffers or the walk
says which commit introduced a line. What changes is that the Switcher — the one
surface whose rows *are* commits — asks the question per Comment, off the
changeset build path entirely.

Blame is bounded by the Comment's own span, not by what is targeted now: `git
blame -L a,b --porcelain <span newest> -- <path>`, and the answer is the Owning
Commit only if it sits inside that same span. Blaming at HEAD instead would give
a Comment filed under `base..mid` an owner it was never about. One blame per
commented path per Switcher open, cached until the Comments or the Review Range
change, so nothing blames when a Comment is written and no cached answer
survives a Range Refresh.

A Comment whose Scope carries no line is Unowned by construction: a `file`
Comment has no lines to blame and a `session` Comment belongs to no commit. A
`commit` Comment is already about one member and is counted there. A line
Comment on a deleted file is Unowned too — there is nothing to blame at the
span's newest member.

## Considered options

Counting a Comment only on the row that *is* its filing — span of one, exact
match — was the alternative, and it is a few lines rather than a blame. It was
rejected because it makes the column empty rather than wrong: nearly every
Comment is written at rest, filed under the whole range, and so would be counted
nowhere. The reader's question is "which commit do I have feedback on", and
exact filing declines to answer it.

Drawing a wide span's count on the row of its newest commit was rejected for the
reason [ADR-0002](0002-comment-identity-is-commit-plus-path.md) rejected keying
on it: the row would then mean "this commit" and "the span ending here" at once.
