---
fragment: 6E48AECF
generation: 0005
branch: master
---

+ Landing
  Where every jump a Review Session makes puts the reader: the arrived-at line a quarter of the way down the window, measured in screen rows so virtual lines above it are counted. One rule for the Hunk walk, the Comment Picker, the Investigation Tab and the export jump alike.
  avoid: centering, zz, scroll position
  under: Review

+ Uncommitted Tip
  The newest member of a Review Range: the working tree, standing in the range past HEAD as though it were a commit. It is targetable like a commit and a Targeted Range may end at it, which is how work that is not committed yet is read inside a running Review Session.
  avoid: working tree row, dirty tip, uncommitted commit
  under: Review

~ Review Range
  The span a Review Session covers: from a chosen base commit through HEAD, base included, with the Uncommitted Tip past HEAD as its newest member.
  avoid: diff range
  was: The span of commits a Review Session covers, from a chosen base commit through HEAD, base included. (the range holds the working tree as a member now, so uncommitted work is readable without ending the session)
