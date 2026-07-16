---
name: spawn-agent
description: Spawn a new coding-agent CLI session (Claude Code, and other agents as they are added) in a background tmux pane, in auto-approve/skip-permissions mode, enabling remote control for agents that support it and returning the shareable session link. Use when the user asks to launch/create another agent session in tmux, start a background agent, or spin up a remote-controllable Claude/agent session.
argument-hint: "Optional: agent name (default claude), a directory to start in, and/or an initial prompt"
---

Spawn a new coding-agent CLI in a background tmux pane, running in auto-approve / skip-permissions mode, and enable remote control **if that agent supports it**. Defaults to the current working directory / tmux session unless the user names a different location.

## Agent registry

Each supported agent defines how to launch it and whether it has a remote-control link. Only add an agent here once its flags are verified.

| Agent    | Keyword(s)        | Launch command                          | Skip-perms flag             | Title rewrite | Remote control          |
|----------|-------------------|-----------------------------------------|-----------------------------|---------------|-------------------------|
| Claude Code | `claude` (default) | `claude --dangerously-skip-permissions` | (part of launch)            | → `✳ Claude Code` | `/remote-control` slash command → prints `https://claude.ai/code/session_...` |

If the user names an agent not in this table, tell them it isn't supported yet (and that the table is where to add it) rather than guessing flags.

## Parsing arguments

Arguments are optional and free-form. Extract:
- **Agent name** — matches a keyword in the registry. Defaults to `claude` if absent.
- **A target directory** — a path (`~/Dev/foo`, `../bar`, absolute). If none, use the current directory/session. Expand `~`/relative to absolute and confirm it exists (`ls -d <path>`) before spawning.
- **An initial prompt** — remaining text to type into the new session once it's up.

## Steps

1. **Verify you are inside tmux.** Run `echo "$TMUX"`. If empty, tell the user this skill requires an active tmux session and stop.

2. **Resolve the agent** from the registry — its launch command, whether it has remote control, and how its title is rewritten.

3. **Spawn the pane.** Use `pop pane` (tmux-pane skill wrapper). Give the pane a name derived from the agent (`claude-spawn`, `codex-spawn`, …). Capture the pane id from stdout — you need it because most agents rewrite the pane title on launch, which breaks name-based lookup.
   ```bash
   PANE_ID=$(pop pane create <agent>-spawn "<launch command>")
   echo "PANE_ID=$PANE_ID"
   ```
   **If the user named a target directory,** add `--project <abs-path>` so the pane spawns in that project's tmux session and starts the agent there:
   ```bash
   PANE_ID=$(pop pane create <agent>-spawn "<launch command>" --project <abs-path>)
   ```
   The tmux session is auto-created if it doesn't exist. Pane ids are global across the tmux server, so later `tmux ... -t "$PANE_ID"` commands work regardless of which session the pane lives in.

4. **Wait for startup.** direnv and agent boot take a few seconds. Sleep ~4s, then confirm the prompt is ready:
   ```bash
   sleep 4; tmux capture-pane -p -t "$PANE_ID" | grep -v '^$' | tail -20
   ```
   Look for the agent's banner and input line. If not ready, sleep and re-capture.

5. **Enable remote control — only if the agent supports it.** For Claude, send the slash command, wait, then capture the link:
   ```bash
   tmux send-keys -t "$PANE_ID" "/remote-control" Enter
   sleep 3; tmux capture-pane -p -t "$PANE_ID" | grep -v '^$' | tail -20
   ```
   Extract the session URL from the output. For agents with no remote control, skip this step.

6. **(Optional) Send an initial prompt.** If the user passed one, type it into the pane after any remote-control step:
   ```bash
   tmux send-keys -t "$PANE_ID" "<the prompt>" Enter
   ```

7. **Report back**: the agent, pane id, session directory, mode (skip-permissions), and the remote-control link (or note that this agent has none). Warn about anything the startup capture flagged (e.g. Claude MCP servers needing auth → `run /mcp` in that pane).

## Notes

- **Always target the pane by id (`$PANE_ID`), not by name** — agents that rewrite the pane title break `pop pane capture <name>` / `find` after startup.
- To spawn several at once, loop over the requested agents/dirs with distinct pane names (`claude-spawn`, `claude-spawn-2`, …). `pop pane create` is idempotent per name and auto-recreates a dead pane. Report each spawned session.
- To add a new agent: verify its auto-approve flag and any remote-control command in a throwaway pane first, then add a registry row. Keep this skill honest — never list an agent whose flags you haven't confirmed.
