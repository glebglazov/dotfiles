---
fragment: 8607A3A9
generation: 0001
branch: master
---

+ Review Session
  A bounded pass over a Review Range in which the reader attaches Comments and ends by exporting them as one body of feedback.
  avoid: review, session
  under: Review

+ Review Range
  The span of commits a Review Session covers, from a chosen base commit through HEAD, base included.
  avoid: changeset, diff range
  under: Review

+ Current Commit
  The single commit inside the Review Range the reader is looking at right now. A Review Session has exactly one at a time and switching it does not end the session.
  avoid: commit cursor, selected commit
  under: Review

+ Comment
  A note the reader attaches during a Review Session, grouped first under the Current Commit it was written against and then under the file it points at.
  avoid: annotation, note
  under: Review

+ Revision Buffer
  A read-only view of one file's contents as of a given commit, opened without changing the working tree. What a reader looks at during a Review Session.
  avoid: commit buffer, historical file
  under: Review

+ Commit Switcher
  The in-session chooser that moves the Current Commit to another commit inside the Review Range.
  avoid: commit picker
  under: Review

+ Start Picker
  The chooser that begins a Review Session by naming the base commit, and so the Review Range.
  avoid: commit picker
  under: Review

~ Comment
  A note the reader attaches during a Review Session. Every Comment has a Scope that says what it is about, and is grouped in the export first under the Current Commit it was written against, then under its Scope.
  was: A note the reader attaches during a Review Session, grouped first under the Current Commit it was written against and then under the file it points at.

+ Scope
  What a Comment is about. One of four widths: a Range, a file, the Current Commit, or the whole Review Session.
  avoid: level, tier, granularity
  under: Review

+ General Note
  The Comment whose Scope is the whole Review Session. At most one exists per session.
  avoid: session comment
  under: Review

+ Stale Session
  A Review Session whose commits no longer resolve, because the stack was amended or rebased underneath it. Its Comments can still be exported but no longer point at anything.
  avoid: broken session, orphaned session
  under: Review
