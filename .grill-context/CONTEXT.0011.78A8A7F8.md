---
fragment: 78A8A7F8
generation: 0011
branch: master
---

- Investigation Tab

+ Working Copy
  The working-tree file behind the Revision Buffer being read, opened in its place in the review's own window. Where a language server attaches and the reader can move freely; the same key that opened it returns to the Review Position.
  avoid: real file, worktree file, investigation
  under: Review

+ Review Position
  Where the review was left when the Working Copy was opened: the targeted span, the Revision Buffer's commit and path, and the cursor's line and column. Held as session facts rather than as a window, a buffer or a tab, so wandering out of the file the reader opened costs nothing. It is not persisted — a restored session lays its reading position out from the Changeset instead.
  avoid: return point, saved cursor, bookmark
  under: Review

+ Review Surface
  A place the review is being read: a Revision Buffer, the Changeset window, or — while the Targeted Range ends at the Uncommitted Tip — a file on disk the Changeset holds. The one predicate behind all three things that must tell the review from the rest of the editor: which way the toggle goes, which colour the Review Badge takes, and which buffers carry the review's own short keys.
  avoid: review buffer, session buffer
  under: Review

+ Review Badge
  The block a running Review Session puts in the statusline: comment count, the span being read, and the reader's place in the Changeset walk. Its colour is the answer to "which side am I on" — lit on a Review Surface, muted on a Working Copy or anywhere else in the editor.
  avoid: statusline badge, review indicator
  under: Review

~ Review Tab
  The tab a Review Session is read in: the Changeset window, and beside it the Revision Buffer being read or the Working Copy opened in its place. A session knows it from the moment it starts or is restored, it is reachable from anywhere in the editor, and it is rebuilt from the session's own state when it is gone.
  avoid: main tab, session tab, home tab
  was: The tab a Review Session is read in: the Revision Buffers and the Changeset window. A session knows it from the moment it starts or is restored, it is reachable from anywhere in the editor, and it is rebuilt from the session's own state when it is gone. (the file being investigated is opened in this tab now rather than in one of its own)
