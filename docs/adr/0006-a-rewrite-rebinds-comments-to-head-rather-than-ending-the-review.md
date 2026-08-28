# A rewrite rebinds Comments to HEAD rather than ending the review

A **Comment** is filed under the **Targeted Range** it was written against, so a
rewrite — an amend, a rebase, a git-pile restack — leaves it pointing at commits
that no longer exist. `persist.lua` declared the answer to this deliberately
absent: the session noticed its commits were gone, called itself stale, and
offered the Comments up for export before the state was lost. In a workflow where
mid-review rewrites are the normal case, that makes every rebase the end of a
review.

Carrying Comments onto the commits that replaced the rewritten ones was
investigated and rejected. It is achievable — jj change-ids resolve an old hash
to the commit that now holds it, exactly and permanently, and `git patch-id
--stable` survives a clean reparent — but neither mechanism covers the workflow.
jj only records the linkage for rewrites performed through jj, so a `git commit
--amend` mints a fresh change-id and breaks the chain, and git-pile is all git; a
`post-rewrite` hook is exact for amend and rebase but never fires for
`cherry-pick`, which is how git-pile moves commits. `patch-id` covers the rest
and is the one that can be silently wrong. The layered result would be a mapping
engine whose correct answers and wrong answers are indistinguishable to the
reader.

So the review takes the other road, and it turns on what a Comment is *for*: it
is feedback in a review, not an annotation on a commit. **When what a Comment is
filed under stops being a member of the Review Range, the Comment is refiled onto
HEAD with its path and line numbers exactly as they were, automatically, and
marked as a Rebound Comment.** No matching, nothing to be wrong about, and the
range is simply re-resolved from `spec.base..HEAD` around it. Staleness stops
being a state the session can be in: `state.stale`, `stale_message` and
`offer_export` go, and `persist.missing` stays on as the thing that *finds* the
gone commits and feeds the rebind.

## Consequences

A **Rebound Comment**'s line numbers are knowingly wrong — the rebind makes no
claim about them, which is why the marker is load-bearing rather than decorative.
It renders on the same path as `resolved`: a glyph in the buffers, a marker on
the Comment Picker's row, cleared when the reader edits the Comment. It stays out
of the export body; it is a note to the reader, not to the agent.

The trigger is membership, not existence, which absorbs a case that predates this
decision. `session.refresh_range` takes the **Uncommitted Tip** out of the range
as soon as the work is committed and, per its own comment, deliberately left that
tip's Comments where they were "because their lines are not the lines that were
committed" — filed under a member that is no longer in the range, listed in the
Picker and drawn nowhere. That exception is deleted; the most frequent rewrite
the reader will meet now goes down the same path as the rarest.

HEAD is the target rather than the newest member of the range, so a rebind can
never land on the Uncommitted Tip. The tip is conditional — `refresh_range` adds
and removes it as the reader works — and a Comment refiled there would be
orphaned a second time the moment the work was committed.

A rebind cannot be undone: the Comment's `commit`/`commit_from` are overwritten
rather than aliased. An alias table would mean every reader of a Comment's
identity consulting it forever, with the aliases accumulating across rebases into
a chain nobody can reason about. The scope and the path survive the rebind even
when that path no longer resolves at HEAD — *which file the reader was talking
about* is the last thing worth throwing away, and `comments.goto_location`
already answers an unopenable path with a notification.

A Comment whose Range had several members is refiled as a Comment on HEAD like
any other; there is no attempt to preserve the span, because there is no mapping
to preserve it with.
