---
name: tdg-task-commit
description: >-
  Turn the work in the current conversation into a single git commit whose
  message is purpose-built to be picked up by a Tripledot backend repo's "create
  JIRA task from PR" GitHub Action (the synced `maybe_create_jira_task_from_pr`
  workflow that fires on PR titles containing [TASK]). Use this only in repos that
  ship that automation, and whenever the user wants to commit the change they just
  made AND have a JIRA issue created from it — phrases like "commit this and create
  a jira task", "make a [TASK] commit", "commit this for jira", "wrap this up as a
  task", or any time they reference the [TASK] PR automation. The skill reads the
  automation workflow to learn the target project, studies recent human-written
  Stories to match the house description format, and writes the commit body in
  JIRA wiki markup (NOT Markdown) so it renders correctly once the Action posts it.
  Reach for this even when the user just says "commit this as a task" without
  naming JIRA — the [TASK] prefix is the tell. Do NOT use it in repos without the
  [TASK] PR→JIRA workflow; there it would produce a commit nothing acts on. Stay
  DORMANT when the work is already tied to a ticket — the branch is named with a
  ticket key (e.g. GS-1234-...), already has commits ahead of its base, or already
  has an open PR. The automation builds the task from the FIRST commit on the
  branch, so a later [TASK] commit would do nothing or create a duplicate. This
  skill fits a fresh branch where the [TASK] commit will be the first one.
---

# TDG task commit

## What this does and why it's fiddly

Tripledot backend repos ship a GitHub Action that watches for pull requests
whose **title** contains `[TASK]`. When it fires, it creates a JIRA issue from
the **first commit of the PR**:

- the commit **subject**, minus the leading `[TASK] `, becomes the JIRA **summary**;
- the commit **body** becomes the JIRA **description**;
- the commit **author's email** becomes the **assignee**.

The catch that makes this worth a skill: the Action posts the description to the
**JIRA REST API v2**, which interprets the string as **wiki markup**, not
Markdown. So a body written in Markdown (`# Heading`, `**bold**`) renders wrong.
You have to write the body in JIRA wiki markup. There's also a heredoc quirk in
the Action that prepends a couple of spaces to the very first body line, which
breaks a heading if it's on line 1.

Your job is to produce a commit whose message survives that whole pipeline and
reads like the team's existing well-written tasks.

## Step 1 — Confirm the repo is wired for this, and read the target project

Find the automation workflow before doing anything else:

```bash
ls .github/workflows | rg -i 'jira|task'
```

Open the matching workflow (commonly
`.github/workflows/maybe_create_jira_task_from_pr.yml` and the reusable
`_maybe_create_jira_task_from_pr.yml` it calls). Read it and extract:

- the **`project_key`** input (e.g. `GS`) — this is the JIRA project you'll study and target;
- the **JIRA site host** from the API `curl` URL (e.g. `tripledotstudios.atlassian.net`) — you'll pass this as the Atlassian `cloudId`;
- confirm the trigger condition (`contains(inputs.pr_title, '[TASK]')`) and the subject/body/assignee mapping described above, in case the automation has drifted.

If there is no such workflow, stop and tell the user this repo isn't set up for
PR-driven JIRA creation, and offer to just write a normal commit instead. Don't
fabricate a project key.

## Step 2 — Learn the house format from real Stories

Don't invent a description shape — mirror what the team actually writes. Use the
Atlassian MCP (`mcp__atlassian__searchJiraIssuesUsingJql`) to pull recent,
**human-written Stories** from the project you found:

```
jql:    project = <KEY> AND issuetype = Story ORDER BY created DESC
fields: ["summary", "description", "created"]
maxResults: ~15
responseContentFormat: markdown
```

Fetch a bit more than you need, then keep **5 non-robot examples**. Skip the
auto-generated ones — they're easy to spot: templated boilerplate, summaries like
`AI: Add ... Game Item to ...`, bodies that are just `Requested by <name>` or a
filled-in form (Bundle ID / App ID / release date). You want the ones with a
real authored structure.

Note: the MCP renders stored content as Markdown for display, so the examples
will *look* like Markdown (`# Context`). That's the display format, not what you
write — see Step 4. What you're harvesting from them is the **structure and
voice**: which sections they use (typically Context / Scope / Acceptance
criteria), how the summary is phrased (`[Area] Sub-area: imperative action`), how
granular the scope bullets and `AC01`-style acceptance criteria are.

Do not name individuals in the commit you produce, even if the examples mention
who requested something.

## Step 2.5 — Check this commit can actually become the task (else stay dormant)

The Action reads `.commits[0]` of the PR — the **oldest** commit on the branch
relative to its base. So the `[TASK]` commit only becomes the JIRA issue if it is
the **first commit ahead of base**. Before writing anything, check that's the
case, and back off when it isn't:

```bash
git rev-parse --abbrev-ref HEAD                 # current branch
git log --oneline origin/master..HEAD           # commits already ahead of base
gh pr view --json number,title 2>/dev/null      # is there already a PR?
```

(Use the repo's real default branch — `master` or `main`.) Stay dormant — and
tell the user why — when any of these hold, because a `[TASK]` commit added now
would not be commit #0 and the automation would either ignore it or has already
created a task:

- the branch name already carries a ticket key (e.g. `GS-1234-...`), so this work
  is already ticketed;
- `origin/master..HEAD` already has commits — your new commit won't be the first;
- a PR already exists for the branch.

The clean fit is a **fresh branch with no commits yet ahead of base**, where this
`[TASK]` commit will be the first. If the user explicitly wants a task anyway in a
non-fresh branch, surface the constraint (they'd need this commit reordered to
first, or a new branch) rather than silently producing a commit nothing acts on.

## Step 3 — Gather the change and its rationale

The substance comes from the current conversation: what was built, why, and any
links worth preserving (Slack threads, related issues). If the conversation is
thin, inspect what's actually changing:

```bash
git status --short
git diff --staged   # and/or unstaged
```

Stage the intended files (`git add`). If you're on the default branch, branch
first — don't commit a task straight onto `master`/`main`.

## Step 4 — Write the commit message in JIRA wiki markup

Compose the message to match the Stories you read, translated into wiki markup.

**Subject line:** `[TASK] <Summary in the house style>`. The `[TASK] ` prefix is
what the PR title needs and what gets stripped for the JIRA summary, so the
remainder must read well on its own as a title. Mirror the example summaries
(e.g. `[Social Login] Add public_id to handshake response`). Keep it tight.

**Body:** JIRA wiki markup, mirroring the sections the Stories use. Wiki markup
cheat sheet (this is the part people get wrong):

| Intent | Markdown (WRONG here) | JIRA wiki markup (CORRECT) |
|---|---|---|
| Heading | `## Context` | `h2. Context` |
| Bold | `**AC01:**` | `*AC01:*` |
| Bullet | `- item` / `* item` | `* item` |
| Nested bullet | 4-space indent | `** item` (double marker) |
| Numbered | `1. item` | `# item` |

Links (Slack, related issues) can go inline as bare URLs — JIRA autolinks them.

**The first-line trap:** the Action prepends ~2 spaces to the first body line,
which would break a leading `h2.`. So **start the body with a one-line plain
sentence** that summarizes the change, then a blank line, then your first
`h2.` heading. The lead sentence absorbs the spaces harmlessly and also reads
well on GitHub (which shows commit bodies as raw text — neither Markdown nor wiki
renders there, so the lead sentence is the one part guaranteed to look fine
everywhere).

Skeleton (adapt sections to whatever the example Stories actually use):

```
[TASK] <Area>: <imperative summary>

<One plain sentence: what this change does and why, in a nutshell.>

h2. Context

<Why this work exists — the problem, the trigger, relevant background.
Drop a Slack/issue link here if there is one.>

h2. Scope

* <concrete thing being done>
** <sub-detail or branch of that thing>
* <another concrete thing>

h2. Acceptance criteria

* *AC01:* <objectively checkable outcome>
```

If the change has a co-author (e.g. pairing with an AI assistant), add the
trailer the repo expects after a blank line at the very end. Be aware it lands in
the JIRA description too, so keep it to the standard one-line trailer.

## Step 5 — Commit, and verify what the Action will read

Write the message with a heredoc so formatting is exact:

```bash
git commit -F - <<'EOF'
[TASK] <Area>: <summary>

<lead sentence>

h2. Context
...
EOF
```

Then confirm the body the Action will actually consume (it reads `messageBody`,
equivalent to `git log %b`):

```bash
git log -1 --format=%b | head -5
```

Check the first line is your plain lead sentence (not a heading), and that
headings/bullets use wiki markup.

## Step 6 — Hand back to the user

This skill stops at the commit. Tell the user the two things they must do for the
automation to fire:

1. Open the PR with **`[TASK]` in the PR title** (the Action keys off the title, then renames it to `[<KEY>-NNNN]`).
2. Keep this commit as the **first commit ahead of base** — the Action reads `.commits[0]` (the oldest commit on the branch), so summary and description come from it. Don't bury it behind earlier commits.

Report the resulting JIRA summary (subject minus `[TASK] `) so they can sanity-check it.
