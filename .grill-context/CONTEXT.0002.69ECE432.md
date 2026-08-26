---
fragment: 69ECE432
generation: 0002
branch: master
---

+ Changeset
  The Current Commit's own Hunks as one ordered list — the walkable form of what that commit changed. What the quickfix window shows during a Review Session.
  avoid: hunk list, diff list, changed files
  under: Review

+ Hunk
  One contiguous run of lines a commit changed in one file. The unit a reader steps through inside a Changeset.
  avoid: chunk, block, diff block
  under: Review

~ Review Range
  The span of commits a Review Session covers, from a chosen base commit through HEAD, base included.
  avoid: diff range
  was: The span of commits a Review Session covers, from a chosen base commit through HEAD, base included. (avoid: changeset, diff range — `changeset` released to name the Current Commit's Hunk list, which the code had already adopted it for)

+ Comment Picker
  The chooser that lists every Comment in a Review Session, grouped by commit, and moves the reader to the one chosen — switching the Current Commit when the Comment belongs to another.
  avoid: comment list, comment browser
  under: Review

~ Changeset
  The Hunks a Review Session is reading right now, as one ordered list: the Current Commit's own Hunks, or the working tree's against HEAD when the session covers no commits. What the quickfix window shows during a Review Session.
  avoid: hunk list, diff list, changed files
  was: The Current Commit's own Hunks as one ordered list — the walkable form of what that commit changed. What the quickfix window shows during a Review Session. (added this session; amended once the working-tree session was settled as having a Changeset of the same shape and no Current Commit)

+ Investigation Tab
  The separate tab a Review Session opens a file's working-tree copy in, where a language server attaches and the reader can move freely across files. Leaving it restores the review tab exactly as it was left.
  avoid: worktree tab, scratch tab, jump target
  under: Review

~ Comment
  A note the reader attaches during a Review Session, identified by the commit it was written against and, for the narrower Scopes, the repository-relative path it points at — never by the buffer it was typed in. Every Comment has a Scope that says what it is about, and is grouped in the export first under the commit, then under its Scope.
  avoid: annotation, note
  was: A note the reader attaches during a Review Session. Every Comment has a Scope that says what it is about, and is grouped in the export first under the Current Commit it was written against, then under its Scope. (identity was the buffer name, which split a file's Revision Buffer from its Investigation Tab copy)
