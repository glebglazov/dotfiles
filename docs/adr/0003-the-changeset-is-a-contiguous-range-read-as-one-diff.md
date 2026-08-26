# The Changeset is a contiguous range of commits read as one diff

A Review Session reads a stack, and the reader wanted to read several related
commits as one pass rather than switching between them. The Changeset is
therefore built from a **Targeted Range** — a contiguous span of the Review
Range — as a single `git diff <parent-of-oldest> <newest>`. A single commit is a
Targeted Range of one, so reading one commit at a time is the degenerate case of
this and behaves exactly as before.

The rejected alternative was to concatenate each targeted commit's own hunks
into one list. It fails on the thing that makes a stack a stack: a file touched
by twelve commits appears as twelve blocks, each opening a *different* Revision
Buffer, because the file at the oldest commit is not the file at the newest.
Walking that list changes the ground under the reader silently — line 139 in one
block and line 211 in another are lines in unrelated texts that share a name.
The file stride assumes a file's hunks are contiguous, and that assumption dies.
Reading one merged diff instead means one file is shown at one version, however
many commits touched it.

Contiguity is not a simplification, it is a requirement: `git diff` cannot
express a gap, so a non-contiguous selection has no merged diff to show.

## Consequences

The change is small because the seam already existed. Building a commit's hunks
was already "diff two points and open the result at the newer one", so it
generalises to a range by passing different points; the entries already carry
the base, and dressing a Revision Buffer already pins gitsigns to it, so the
signs become the whole range's changes for free.

What is lost is per-commit attribution *inside* the range. A hunk belongs to the
range, not to any one commit in it, and nothing on screen can say which commit
introduced a given line. This was accepted because it is the same trade a
reviewer makes when reading a squashed pull request, and because narrowing the
range to one commit recovers the attribution exactly.

The newest commit of the Targeted Range becomes the Current Commit: it is the
commit whose content the Revision Buffers show.
