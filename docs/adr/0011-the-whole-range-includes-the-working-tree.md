# The whole range includes the working tree

[ADR-0004](0004-the-working-tree-is-a-member-of-the-review-range.md) made the
Uncommitted Tip a member of the Review Range, but kept it out of "the whole
range": a session opened on its newest commit, and the switcher's reset key put
that span back. The reasoning was that a review of a branch is a review of what
is committed on it. In practice the reader almost always wants the opposite:
the branch as it stands on disk, with the fix made a minute ago in the same
diff. Getting there took the switcher and two marks on every start.

"The whole range" is therefore the oldest member through the newest one, which
is the Uncommitted Tip while the working tree is dirty. A session opens on it,
the reset key puts it back, and a Range Refresh widens a resting reading onto a
tip that has just appeared, the same way it widens onto commits that arrive.

The committed part of the branch on its own stays one move away: mark its
oldest and newest commits in the switcher. It no longer has a key of its own,
because it is the rarer reading.

## Consequences

`<LEADER>rS` stops meaning "show me my uncommitted work". It is now the same
range as `<LEADER>rs`, opened on one commit alone, and it needs a highlighted
commit hash to name that commit. In normal mode it only says so. The working
tree alone is still one keypress in the switcher: `<Enter>` on its row.

With no key starting a session on the working tree alone, `spec.uncommitted`
leaves the session spec. Sessions persisted in that shape still convert on
read, as ADR-0004 required.

What ADR-0004 said about a target ending at a tip that vanishes still holds:
work that has just been committed is still the work on the screen, so the span
follows it onto HEAD.
