# A file on disk is commentable at the version it holds

[ADR-0002](0002-comment-identity-is-commit-plus-path.md) refused line Comments
outside a Revision Buffer, and the reason was sound: "line numbers do not
normalise, and cannot. A working-tree buffer shows the file at HEAD, so line 42
there is not line 42 in an older commit." The refusal was enforced by one
predicate, `lines_true = loc.revision or is_uncommitted(commit)`, written twice —
in `state.scopes_here` and in `render.buffer`.

The refusal costs more than it protects. A reader who opens a real file during a
review — for the language server, or because the feedback is about a file the
change never touched — can say `file`, `commit` and `session` but not "this
line", which is most of what a review is; and Comments made in a Revision Buffer
are invisible in the real copy of the same file.

The predicate is therefore replaced by a **Comment Anchor**, resolved once per
buffer in `buffers.locate`: ask `git diff --quiet <span newest> -- <path>`
whether the copy on disk *is* the span's own copy. If it is, the buffer is filed
under the Targeted Range — the same filing a Revision Buffer of that file gets,
so both views hold one set of Comments. If it is not, the text on screen belongs
to the working tree, and the buffer is filed under the newest member of the
Review Range whose copy it is: the Uncommitted Tip when the file is modified,
HEAD when the tree is clean and the span merely ends earlier. Every Scope is
offered at every anchor, and the anchor that files a Comment is the anchor that
draws it.

ADR-0002's objection is answered rather than overruled: lines are true because
the anchor is the version whose lines they are, tested per file rather than
assumed per buffer kind.

## Consequences

Resolving the anchor in `locate` is what keeps the rule single: `scopes_here`,
`render.buffer`, `marks` and `state.find` read `from`/`commit` off the same
answer, and the twice-written `lines_true` goes away. The check is one `git diff
--quiet` per file, cached per buffer and dropped when the buffer is written.

An ordinary file does **not** become a Review Surface. It carries Comment marks
and the `<leader>` Comment keys, and not `]e`, `]f`, `<Tab>` or the lit Review
Badge — widening `buffers.surface` would shadow `]c` and `]f` on every file in
the repository, which is the thing that predicate exists to prevent. Diff Marks
keep their own gate for the same reason: an unrelated file holds none of the
Targeted Range's diff.

A line Comment written on a modified file is filed under the Uncommitted Tip and
so is not drawn while a committed span is targeted — the lines being read there
are another version's. It is an Unowned Comment in the Commit Switcher, and the
Comment Picker reaches it.

## Considered options

Filing a disk line Comment under the span being read with the lines as read —
one line of code, delete the gate — was rejected because it is exactly what
ADR-0002 forbade, and the failure is silent: the Revision Buffer draws the
Comment at line 42 of a different text.

Filing every disk line Comment under the Uncommitted Tip is always truthful and
was rejected because it never joins the span's set, so a Comment made in a
Revision Buffer still would not appear in the real file — half of what was asked
for.
