---
fragment: E42A20F8
generation: 0006
branch: master
---

~ Uncommitted Tip
  The working tree standing in a Review Range past HEAD as though it were a commit, under the identity `uncommitted`. It is in the range only while the working tree has uncommitted changes, it is never targeted by starting a session, and a Targeted Range that ends at it is read from the files on disk rather than from Revision Buffers.
  avoid: working tree row, dirty tip, uncommitted commit
  was: The newest member of a Review Range: the working tree, standing in the range past HEAD as though it were a commit. It is targetable like a commit and a Targeted Range may end at it, which is how work that is not committed yet is read inside a running Review Session. (its presence is conditional on there being uncommitted work, and its content is read on disk)

~ Review Range
  The span a Review Session covers: from a chosen base commit through HEAD, base included, plus the Uncommitted Tip past HEAD while the working tree has uncommitted changes.
  avoid: diff range
  was: The span a Review Session covers: from a chosen base commit through HEAD, base included, with the Uncommitted Tip past HEAD as its newest member. (the tip is only a member while there is uncommitted work)

~ Changeset
  The Hunks a Review Session is reading right now, as one ordered list: the Targeted Range's combined changes against the commit before it. A range ending at the Uncommitted Tip is read from the files on disk; any other range from Revision Buffers. What the quickfix window shows during a Review Session.
  avoid: hunk list, diff list, changed files
  was: The Hunks a Review Session is reading right now, as one ordered list: the Targeted Range's combined changes against the commit before it, or the working tree's against HEAD when the session covers no commits. What the quickfix window shows during a Review Session. (the working-tree session is no longer a kind of its own — it is a range whose only member is the Uncommitted Tip)
