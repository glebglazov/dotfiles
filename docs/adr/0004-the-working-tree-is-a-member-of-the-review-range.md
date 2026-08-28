# The working tree is a member of the Review Range

A Review Session started against a base showed only committed work, so a fix made
during the review — or unstaged work that predated it — was invisible, and the
only way to look at it was `<LEADER>rS`, which started a session of a different
kind. That path silently converted the running session: it cleared the range and
left every comment behind, attached to commits the session no longer held. The
working tree is therefore a **member of the Review Range**, the Uncommitted Tip,
carried under the sentinel identity `uncommitted` past HEAD. It is targetable
like a commit, a Targeted Range may end at it, and it is a member only while the
working tree is dirty — recomputed at start, at restore and whenever the Commit
Switcher opens.

This works because `git diff <ref>` with no second ref *is* the working tree
against that ref, so a span ending at the tip is still one diff command, which is
what [ADR-0003](0003-the-changeset-is-a-contiguous-range-read-as-one-diff.md)
requires of every Changeset.

The rejected alternative was an `include_uncommitted` boolean on the session,
appending the working tree's hunks to whatever Changeset was built. It adds a
second axis that the Targeted Range, the Changeset, comment identity and the
switcher must each learn about, and it produces Changesets that are two diffs
stapled together — a file touched by a commit and again on disk appearing twice
at two versions, which is precisely what ADR-0003 ruled out. A member of the
range teaches those four concepts nothing: they gain one more thing to point at.

## Consequences

The working-tree session stops being a kind of its own. It is a session whose
range holds only the tip, which collapses `spec.uncommitted`, `worktree_hunks`,
the switcher's "no commits to switch between" refusal and the
`if state.current then … else …` forks in `session.start`, `persist.restore` and
`buffers.locate` into one path. Sessions persisted in the old shape convert on
read, as the three existing migrations do — the house rule being that a
discarded session loses review work that cannot be recovered.

`<LEADER>rS` becomes "show me my uncommitted work": outside a session it starts
one on the tip alone, inside a session it targets the tip. There is no longer a
keypress that destroys a running review.

A Targeted Range ending at the tip is read from the files on disk rather than
from Revision Buffers, since a Revision Buffer cannot hold uncommitted content.
A language server attaches to those files, so no Investigation Tab is needed for
them.

Two places must know the sentinel is not a commit: `persist.missing`, which would
otherwise run `merge-base --is-ancestor uncommitted HEAD` and mark every session
stale, and the diff builder, where the tip's base is HEAD.

"The whole range", which is what a session opens on and what the switcher's
reset key puts back, means the range up to its newest *commit*. A review of a
branch is a review of what is committed on it, and the tip is a row the reader
targets on purpose — a reset that swept it in would leave no way back to the
branch as it stands. A session whose range holds nothing but the tip is the one
exception: there is nothing else to put back. For the same reason the tip's own
Changeset takes in untracked files, which `git diff <ref>` cannot mention: a file
git has never seen is uncommitted work like any other.

Comments made against the tip carry `commit = 'uncommitted'` and stay exactly
where they are once that work is committed, filed in the export as uncommitted at
the time of review. Carrying them onto the new commit is the same dishonesty
`persist.lua` already refuses for a rebase: the lines may differ between what was
commented on and what was committed. Targeting, however, does follow — a target
ending at a tip that has just vanished falls back to HEAD alone, so the screen
after the commit shows what the screen before it showed.
