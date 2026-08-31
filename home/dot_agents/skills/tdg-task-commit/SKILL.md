---
name: tdg-task-commit
description: >-
  Turn conversation work into a git commit for Tripledot backend repos' [TASK]
  PR→JIRA GitHub Action (`maybe_create_jira_task_from_pr`). Use when the user
  wants to commit changes AND auto-create a JIRA task — e.g. "commit this and
  create a jira task", "make a [TASK] commit", "commit this for jira", "wrap
  this up as a task", or any [TASK] automation reference; also when they say
  "commit this as a task" without naming JIRA. Only for repos that ship
  this automation. Stay DORMANT if the branch already has a ticket key (e.g.
  GS-1234-...), commits ahead of base, or an open PR — the Action uses the
  FIRST commit only; later [TASK] commits noop or duplicate. For fresh
  branches where the [TASK] commit is first.
---

# TDG task commit

## What this does and why it's fiddly

Tripledot backend repos ship a GitHub Action that watches for pull requests
whose **title** contains `[TASK]`. When it fires, it creates a JIRA issue from
the **first commit of the PR**:

- the commit **subject**, minus the leading `[TASK] `, becomes the JIRA **summary**;
- the commit **body** becomes the JIRA **description**;
- the commit **author's email** becomes the **assignee**.

The catch that makes this worth a skill: the Action posts the description to
the **JIRA REST API v2**, which interprets the string as **wiki markup**, not
Markdown. So a body written in Markdown (`# Heading`, `**bold**`) renders
wrong. There's also a heredoc quirk in the Action that prepends a couple of
spaces to the very first body line, which breaks a heading if it's on line 1.

The task **content** is not this skill's job: the `tdg-jira-task` skill owns
the writing discipline and the user checkpoint. This skill owns the pipeline —
verifying the automation exists, verifying this commit can become the task,
rendering the approved content into wiki markup, and committing it intact.

## Step 1 — Confirm the repo is wired for this, and read the target project

Find the automation workflow before doing anything else:

```bash
ls .github/workflows | rg -i 'jira|task'
```

Open the matching workflow (commonly
`.github/workflows/maybe_create_jira_task_from_pr.yml` and the reusable
`_maybe_create_jira_task_from_pr.yml` it calls). Read it and extract:

- the **`project_key`** input (e.g. `GS`) — the JIRA project to target;
- the **JIRA site host** from the API `curl` URL (e.g.
  `tripledotstudios.atlassian.net`) — pass this as the Atlassian `cloudId`;
- confirm the trigger condition (`contains(inputs.pr_title, '[TASK]')`) and
  the subject/body/assignee mapping above, in case the automation has drifted.

If there is no such workflow, stop and tell the user this repo isn't set up
for PR-driven JIRA creation, and offer to just write a normal commit instead.
Don't fabricate a project key.

## Step 2 — Check this commit can actually become the task (else stay dormant)

The Action reads `.commits[0]` of the PR — the **oldest** commit on the branch
relative to its base. So the `[TASK]` commit only becomes the JIRA issue if it
is the **first commit ahead of base**. Before writing anything, check that's
the case, and back off when it isn't:

```bash
git rev-parse --abbrev-ref HEAD                 # current branch
git log --oneline origin/master..HEAD           # commits already ahead of base
gh pr view --json number,title 2>/dev/null      # is there already a PR?
```

(Use the repo's real default branch — `master` or `main`.) Stay dormant — and
tell the user why — when any of these hold, because a `[TASK]` commit added
now would not be commit #0 and the automation would either ignore it or has
already created a task:

- the branch name already carries a ticket key (e.g. `GS-1234-...`), so this
  work is already ticketed;
- `origin/master..HEAD` already has commits — your new commit won't be the first;
- a PR already exists for the branch.

The clean fit is a **fresh branch with no commits yet ahead of base**, where
this `[TASK]` commit will be the first. If the user explicitly wants a task
anyway in a non-fresh branch, surface the constraint (they'd need this commit
reordered to first, or a new branch) rather than silently producing a commit
nothing acts on.

## Step 3 — Stage the change, draft the content

Stage the intended files (`git add`). If you're on the default branch, branch
first — don't commit a task straight onto `master`/`main`.

Then invoke the **`tdg-jira-task`** skill to produce the summary and
description. It gathers substance from the conversation and the staged diff,
finds the precedent ticket, applies the house writing discipline, and runs its
own draft-review checkpoint with the user. Give it the project key and host
from Step 1. Proceed only with the **approved** Markdown draft.

## Step 4 — Render the approved draft into the commit message

**Subject line:** `[TASK] <approved summary>`. The `[TASK] ` prefix is what
the PR title needs and what gets stripped for the JIRA summary.

**Body:** translate the approved Markdown to JIRA wiki markup:

| Intent | Markdown (WRONG here) | JIRA wiki markup (CORRECT) |
|---|---|---|
| Heading | `## Context` | `h2. Context` |
| Bold | `**AC01:**` | `*AC01:*` |
| Bullet | `- item` / `* item` | `* item` |
| Nested bullet | 2-space indent | `** item` (double marker) |
| Numbered | `1. item` | `# item` |

Links stay as bare URLs — JIRA autolinks them. Translation only: the approved
content's wording does not change here.

**The first-line trap:** the Action prepends ~2 spaces to the first body
line, which would break a leading `h2.`. The draft's lead sentence handles
this — keep it as the first body line, blank line, then the first `h2.`
heading. The lead sentence absorbs the spaces harmlessly and also reads well
on GitHub (which shows commit bodies as raw text — neither Markdown nor wiki
renders there).

If the change has a co-author (e.g. pairing with an AI assistant), add the
trailer the repo expects after a blank line at the very end. It lands in the
JIRA description too, so keep it to the standard one-line trailer.

## Step 5 — Commit, and verify what the Action will read

Write the message with a heredoc so formatting is exact:

```bash
git commit -F - <<'EOF'
[TASK] <approved summary>

<lead sentence>

h2. Context
...
EOF
```

Then confirm the body the Action will actually consume (it reads
`messageBody`, equivalent to `git log %b`):

```bash
git log -1 --format=%b | head -5
```

Check the first line is the plain lead sentence (not a heading), that
headings/bullets use wiki markup, and that the subject carries no bracketed
`[Area]` tag.

## Step 6 — Hand back to the user

This skill stops at the commit. Tell the user the two things they must do for
the automation to fire:

1. Open the PR with **`[TASK]` in the PR title** (the Action keys off the
   title, then renames it to `[<KEY>-NNNN]`).
2. Keep this commit as the **first commit ahead of base** — the Action reads
   `.commits[0]` (the oldest commit on the branch), so summary and description
   come from it. Don't bury it behind earlier commits.

Report the resulting JIRA summary (subject minus `[TASK] `) so they can
sanity-check it.
