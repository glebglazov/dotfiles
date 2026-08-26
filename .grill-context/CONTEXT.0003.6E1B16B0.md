---
fragment: 6E1B16B0
generation: 0003
branch: master
---

+ Targeted Range
  The contiguous span of the Review Range the Changeset is currently built from. A single commit is a Targeted Range of one, and an untargeted session's is the whole Review Range.
  avoid: selection, targeted commits, sub-range
  under: Review

~ Current Commit
  The newest commit of the Targeted Range: the commit whose content the Revision Buffers show. A Review Session has exactly one at a time.
  was: The single commit inside the Review Range the reader is looking at right now. A Review Session has exactly one at a time and switching it does not end the session.

~ Changeset
  The Hunks a Review Session is reading right now, as one ordered list: the Targeted Range's combined changes against the commit before it, or the working tree's against HEAD when the session covers no commits. What the quickfix window shows during a Review Session.
  avoid: hunk list, diff list, changed files
  was: The Hunks a Review Session is reading right now, as one ordered list: the Current Commit's own Hunks, or the working tree's against HEAD when the session covers no commits. What the quickfix window shows during a Review Session. (built from a Targeted Range now, so one file is shown at one version however many commits touched it)

~ Comment
  A note the reader attaches during a Review Session, identified by the Targeted Range it was written against and, for the narrower Scopes, the repository-relative path it points at — never by the buffer it was typed in. Every Comment has a Scope that says what it is about, and is grouped in the export first under that range, then under its Scope.
  avoid: annotation, note
  was: A note the reader attaches during a Review Session, identified by the commit it was written against and, for the narrower Scopes, the repository-relative path it points at — never by the buffer it was typed in. Every Comment has a Scope that says what it is about, and is grouped in the export first under the commit, then under its Scope. (a range of one commit is the old identity, so this widens rather than replaces it)
