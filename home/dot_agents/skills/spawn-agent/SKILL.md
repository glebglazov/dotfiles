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
3. Use tmux directly. Target the caller's `$TMUX_PANE`, or an explicit pane
   supplied by the user. If neither exists, ask for a target pane. Split that
   pane side by side, without changing focus:
   `tmux split-window -h -d -P -F '#{pane_id}' -t "$target_pane" -c "$directory"`.
   Capture the returned pane ID. Wait for its shell to be ready, then send the
   quoted launch command with one leading space, so shell history skips it:
   `tmux send-keys -l -t "$pane_id" " $launch_command"`. Submit with
   `tmux send-keys -t "$pane_id" Enter`. Use the pane ID for all
   later operations; titles can change. If the split fails, report the error
   rather than creating a different window.
4. Check startup for up to two minutes, with waits of at most ten seconds.
   Require a task-specific response or the caller's acknowledgement file. For
   an empty session, require a ready input prompt. An echoed command is not
   evidence of startup. Report unresolved authentication or approval prompts.
5. Return the harness, pane ID, directory, settings, and observed result. On
   failure or timeout, retain the pane and prompt file. Inspect that pane before
   retrying; do not launch a duplicate.

If remote control was requested, discover its support from the installed CLI,
enable it, and return the link. Report when it is unsupported.
