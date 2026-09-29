---
name: spawn-agent
description: Launch a coding agent in tmux with an optional task or handoff file. Also used by handoff-and-continue.
argument-hint: "[harness] [directory] [task or handoff path]"
---

# Spawn an agent

1. Use the requested CLI and directory; default to the current harness and
   directory. If the harness is unknown, ask. Read the installed CLI's help to
   establish its fresh-session command and initial-prompt options. Report
   unsupported settings instead of guessing flags. Preserve requested model and
   permission settings; otherwise use CLI defaults. Launching alone does not
   authorize a permissions bypass.
2. Put a long task in a unique OS temporary file, or use the supplied handoff
   file. Pass a short prompt with its absolute path. Prefer CLI prompt options;
   otherwise wait for the input prompt and paste through a tmux buffer. Quote
   shell arguments; keep task text out of shell code.
3. Use **tmux-pane** to create a uniquely named pane with
   `pop pane create <name> <command> --project <absolute-directory>`. This also
   works outside tmux. If pop is unavailable, use tmux directly with an explicit
   working directory. Capture the pane ID and use it thereafter: agents can
   change pane titles.
4. Check startup for up to two minutes, with waits of at most ten seconds.
   Require a task-specific response or the caller's acknowledgement file. For
   an empty session, require a ready input prompt. An echoed command is not
   evidence of startup. Report unresolved authentication or approval prompts.
5. Return the harness, pane ID, directory, settings, and observed result. On
   failure or timeout, retain the pane and prompt file. Inspect that pane before
   retrying; do not launch a duplicate.

If remote control was requested, discover its support from the installed CLI,
enable it, and return the link. Report when it is unsupported.
