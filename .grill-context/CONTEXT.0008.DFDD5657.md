---
fragment: DFDD5657
generation: 0008
branch: master
---

~ Commit Switcher
  The in-session chooser over the members of the Review Range — its commits and, while there is uncommitted work, the Uncommitted Tip. It targets one member, a marked run of them, or the whole range again, and shows the Targeted Range on its rows.
  avoid: commit picker
  was: The in-session chooser that moves the Current Commit to another commit inside the Review Range. (it targets spans rather than single commits, and the range holds the Uncommitted Tip)

~ Targeted Range
  The contiguous span of the Review Range the Changeset is currently built from. A single member is a Targeted Range of one, and the whole Review Range is the resting state rather than a selection — which is why nothing on the Commit Switcher's rows marks it.
  avoid: selection, targeted commits, sub-range
  was: The contiguous span of the Review Range the Changeset is currently built from. A single commit is a Targeted Range of one, and an untargeted session's is the whole Review Range. (the widest span is the absence of a selection, and a span may end at the Uncommitted Tip)
