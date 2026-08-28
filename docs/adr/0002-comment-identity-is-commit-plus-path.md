# A Comment is identified by its commit and path, not by the buffer it was typed in

The review's Comment store keyed each Comment by `nvim_buf_get_name(0)` — the
buffer it was written in. That was deliberate: a Revision Buffer is a
`fugitive://` name carrying the commit, so keying on it gave each commit its own
set of Comments on the same file for free, with no extra field to maintain.

It is wrong as soon as the same file is reachable under two names. It already is:
the working-tree jump opens the real file on disk, so a `file`-scope Comment made
there and one made in the Revision Buffer are two Comments on the same file at
the same commit. `state.find` cannot match them, so the form offers to create
rather than edit; the export prints both under one path and one heading, looking
like a duplicate with no explanation; and `render.buffer`, which walks Comments
by buffer name, draws each one only in the buffer it was typed in — so returning
to the Revision Buffer shows the file as uncommented.

A Comment is therefore identified by `(commit, repository-relative path)`. The
property that motivated buffer keying survives untouched, because the commit is
still half the key: one file read at two commits still keeps two sets of
Comments. What changes is that the *same* file at the *same* commit is one thing
however it was opened.

## Consequences

`render.buffer` resolves a buffer to `(commit, rel)` rather than comparing names:
`buffers.info` already yields both for a Revision Buffer, and a working-tree
buffer is the current commit's `rel` with the repo root stripped. This is what
makes the Investigation Tab able to show and add Comments at all.

Sessions on disk store `path` as a buffer name, so a restore migrates on read —
`buffers.parse` recovers `sha` and `rel` from a `fugitive://` name, and a real
path becomes relative to the root. Migrating rather than version-bumping is
deliberate: a discarded session loses review work that cannot be recovered, and
the conversion is a few lines.

Line numbers do not normalise, and cannot. A working-tree buffer shows the file
at HEAD, so line 42 there is not line 42 in an older commit. `range` Comments
are therefore not offered outside a Revision Buffer and not drawn in a
working-tree buffer — the scopes that carry lines are exactly the ones whose
lines would be wrong there, and the scope that carries none is the one that
stays available.

## Considered options

Keeping buffer keying and treating the working tree as a separate surface was the
alternative: no migration, no resolution step. It was rejected because it makes
the duplicate reachable rather than impossible, and the duplicate is silent — the
reader sees a badge count go up and no other sign, then finds two identical
Comments in the export with nothing to distinguish them.

## Amendment — the commit half of the key widens to a range

The Changeset is now built from a contiguous range of commits read as one diff,
so the commit a Comment is written against is no longer always a single commit.
A Comment is therefore identified by `(range, repository-relative path)`, where
a range is the pair of its oldest and newest commits.

This widens the decision above rather than replacing it. A single commit is a
range of one, so every Comment this ADR describes keeps exactly the identity it
had, and the property that motivated the original key survives untouched: one
file read across two different spans still keeps two sets of Comments.

The alternative was to key on the range's newest commit alone, which would have
left `(commit, path)` literally unchanged. It was rejected because the same key
would then mean two different things — "this commit" and "the span ending here"
— and the export would file feedback about three commits under one of them with
nothing saying so. A Comment shows exactly when the span it was written against
is the one being read; the Comment Picker reaches the rest.

## Amendment — the range half is reassignable

This ADR says a Comment *is identified by* the range it was written against,
which reads as an immutable key. It is not one, and
[ADR-0006](0006-a-rewrite-rebinds-comments-to-head-rather-than-ending-the-review.md)
is why: when what a Comment is filed under stops being a member of the Review
Range, the range half is overwritten with HEAD and the Comment is marked as
rebound. A Comment is therefore **filed under** `(range, path)` rather than
identified by it.

Nothing above changes for a Comment whose commits are still there, which is every
Comment in a review that has not been rewritten underneath. What changes is that
the key is the review's to reassign, once, on a rewrite — and that reassigning it
is how a rewrite stops throwing review work away. The path half stays immutable
and stays the reader's anchor: the rebind moves the range and never the path, even
when the path no longer resolves at HEAD.
