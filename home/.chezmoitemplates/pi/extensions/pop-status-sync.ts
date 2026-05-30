/**
 * pop-status-sync
 *
 * pi extension that keeps the surrounding pop tmux pane's status in sync with
 * the agent's lifecycle:
 *   - working → pi is busy (user submitted input, or a tool is running)
 *   - unread  → pi finished a turn, awaiting the user
 *
 * `clear` is also sent on `session_start`, but only as housekeeping: pop
 * ignores `set-status clear` for untracked panes, so it cannot pollute the
 * dashboard. For already-tracked panes it clears any stale "working" status
 * left over from a crashed previous run.
 *
 * Uses TCP API to pop monitor daemon, instead of calling the pop binary
 * directly. This matches the approach in ~/.local/bin/pop-status.
 *
 * Installed to ~/.pi/agent/extensions/pop-status-sync.ts via chezmoi.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	const paneID = process.env.TMUX_PANE;
	if (!paneID) return;

	// TCP connection settings (match Claude Code hook defaults)
	const host = process.env.LOCAL_NETWORK_HOST ?? "127.0.0.1";
	const port = process.env.POP_MONITOR_PORT ?? "57341";
	const addr = process.env.POP_MONITOR_ADDR ?? `${host}:${port}`;

	const setStatus = (status: "working" | "unread" | "clear") => {
		// Build JSON payload matching pop-status / Claude Code hook format
		const payload = JSON.stringify({
			cmd: "set-status",
			pane_id: paneID,
			status: status,
			label: "pi",
		});

		// Parse host:port from addr
		const [h, p] = addr.split(":");

		// Fire-and-forget via netcat; swallow errors so a failed status
		// update never breaks the agent. Uses same TCP API as Claude Code.
		pi.exec("bash", ["-c", `echo '${payload}' | nc -w1 "${h}" "${p}" 2>/dev/null || true`]);
	};

	// UserPromptSubmit → working
	pi.on("input", async (event) => {
		if (event.source !== "extension") {
			setStatus("working");
		}
		return { action: "continue" };
	});

	// PreToolUse → working
	pi.on("tool_call", async () => {
		setStatus("working");
		return undefined;
	});

	// Stop → unread (agent finished a turn — flag the user)
	pi.on("agent_end", async () => {
		setStatus("unread");
	});

	// Housekeeping: clear any stale "working" status left over from a
	// previous run on session start, so a freshly resumed pane isn't stuck
	// "working". Pop treats `clear` as a no-op for untracked panes, so this
	// cannot register a brand-new pane and skew the dashboard sort.
	pi.on("session_start", async () => {
		setStatus("clear");
	});
}
