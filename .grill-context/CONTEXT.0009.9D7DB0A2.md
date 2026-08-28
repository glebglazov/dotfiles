---
fragment: 9D7DB0A2
generation: 0009
branch: master
---

- Stale Session

+ Rebound Comment
  A Comment refiled onto HEAD, with its path and line numbers exactly as they were, because what it was filed under stopped being a member of the Review Range. It is marked as rebound wherever it is drawn, because its lines no longer describe anything.
  avoid: orphaned comment, carried comment, migrated comment
  under: Review

+ Resolved Comment
  A Comment the reader has dealt with and kept: still in the Review Session, still drawn where it was written, and absent from the export.
  avoid: done comment, closed comment, dismissed comment
  under: Review

~ Comment
  A note the reader attaches during a Review Session, filed under a Targeted Range and, for the narrower Scopes, the repository-relative path it points at — never the buffer it was typed in. Where it is filed is reassignable: a rewrite refiles it onto HEAD rather than losing it.
  avoid: annotation, note
  was: A note the reader attaches during a Review Session, identified by the Targeted Range it was written against and, for the narrower Scopes, the repository-relative path it points at — never by the buffer it was typed in. Every Comment has a Scope that says what it is about, and is grouped in the export first under that range, then under its Scope. (a rewrite reassigns the range half of the identity, so a Comment is filed under a range rather than identified by the one it was written against)

~ Comment Picker
  The chooser over every Comment in a Review Session, grouped by commit — and the one surface from which any of them can be jumped to, resolved or deleted, including the ones no buffer of the review can draw.
  avoid: comment list, comment browser
  was: The chooser that lists every Comment in a Review Session, grouped by commit, and moves the reader to the one chosen — switching the Current Commit when the Comment belongs to another. (it acts on Comments as well as reaching them)
