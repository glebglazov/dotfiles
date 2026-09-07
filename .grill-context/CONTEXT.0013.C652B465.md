---
fragment: C652B465
generation: 0013
branch: master
---

+ Owning Commit
  The one member of a Comment's span that changed the lines the Comment points at, found by blaming those lines at the span's newest member. What the Commit Switcher counts a Comment on, so a Comment written while a wide span was read still lands on one row.
  avoid: attributed commit, blamed commit, source commit
  under: Review

+ Unowned Comment
  A Comment with no Owning Commit: one whose Scope carries no line, or one whose lines its span never changed. It is reachable from the Comment Picker alone, and the Commit Switcher says only how many of them there are.
  avoid: unattributed comment, orphan comment, loose comment
  under: Review

~ Commit Switcher
  The in-session chooser over the members of the Review Range — its commits and, while there is uncommitted work, the Uncommitted Tip. It targets one member, a marked run of them, or the whole range again, shows the Targeted Range on its rows, and counts each Comment on the row of its Owning Commit alone.
  avoid: commit picker
  was: The in-session chooser over the members of the Review Range — its commits and, while there is uncommitted work, the Uncommitted Tip. It targets one member, a marked run of them, or the whole range again, and shows the Targeted Range on its rows. (a Comment counted on every row of its span, and a review at rest files every Comment under the whole range)

+ Comment Anchor
  The version of a file a Comment written in it is filed under: the Targeted Range when the copy on disk is that span's own copy, and otherwise the newest member of the Review Range whose copy it is. Resolved once per buffer, and what makes a line Comment's line true in every buffer that draws it.
  avoid: filing, binding, anchor commit
  under: Review

~ Working Copy
  A file of the repository read from disk during a Review Session — the working-tree file behind the Revision Buffer, opened in its place, or any other file the reader opens. Where a language server attaches and the reader can move freely; every Scope of Comment can be written in it, filed under its Comment Anchor. From the one opened in a Revision Buffer's place, the same key that opened it returns to the Review Position.
  was: The working-tree file behind the Revision Buffer being read, opened in its place in the review's own window. Where a language server attaches and the reader can move freely; the same key that opened it returns to the Review Position. (a file the Changeset does not hold is readable and commentable too)

~ Review Surface
  A place the review is being read: a Revision Buffer, the Changeset window, or — while the Targeted Range ends at the Uncommitted Tip — a file on disk the Changeset holds. The one predicate behind the three things that must tell the review from the rest of the editor: which way the toggle goes, which colour the Review Badge takes, and which buffers carry the review's own short keys. Comment marks and the Comment keys are not among them — they follow the Comment Anchor, so they reach a Working Copy that is no Review Surface.
  avoid: review buffer, session buffer
  was: A place the review is being read: a Revision Buffer, the Changeset window, or — while the Targeted Range ends at the Uncommitted Tip — a file on disk the Changeset holds. The one predicate behind all three things that must tell the review from the rest of the editor: which way the toggle goes, which colour the Review Badge takes, and which buffers carry the review's own short keys. (Comments are now written and drawn in files that are not Review Surfaces)
