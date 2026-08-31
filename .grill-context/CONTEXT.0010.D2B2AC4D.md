---
fragment: D2B2AC4D
generation: 0010
branch: master
---

+ Range Refresh
  The one recompute of a Review Range's membership: base..HEAD asked again, arrivals admitted, what departures took refiled onto HEAD, and the Targeted Range repaired around both. Runs at a start, at a restore, and whenever the Commit Switcher opens — nowhere else, so the range is asked again where its members are read.
  avoid: range reresolve, membership check, refresh
  under: Review

~ Review Range
  The span a Review Session covers: from a chosen base commit through HEAD, base included, plus the Uncommitted Tip past HEAD while the working tree has uncommitted changes. Its membership is live rather than taken at the start — every Range Refresh admits the commits made or pulled since the last one.
  avoid: diff range
  was: The span a Review Session covers: from a chosen base commit through HEAD, base included, plus the Uncommitted Tip past HEAD while the working tree has uncommitted changes. (membership was only ever recomputed for the tip, so commits arriving during a session never joined)

~ Targeted Range
  The contiguous span of the Review Range the Changeset is currently built from. A single member is a Targeted Range of one, and the whole Review Range is the resting state rather than a selection — which is why nothing on the Commit Switcher's rows marks it, and why a Range Refresh widens it onto arrivals while leaving a narrower span exactly as the reader chose it.
  avoid: selection, targeted commits, sub-range
  was: The contiguous span of the Review Range the Changeset is currently built from. A single member is a Targeted Range of one, and the whole Review Range is the resting state rather than a selection — which is why nothing on the Commit Switcher's rows marks it. (the resting state follows the range's membership, a chosen span does not)
