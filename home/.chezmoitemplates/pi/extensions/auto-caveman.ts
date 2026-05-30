import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { homedir } from "node:os";

const CAVEMAN_SKILL_PATH = join(homedir(), ".pi/agent/skills/caveman/SKILL.md");
const CAVEMAN_REPO_URL = "https://github.com/glebglazov/pi-caveman-skill";

function isCavemanInstalled(): boolean {
	return existsSync(CAVEMAN_SKILL_PATH);
}

function getCavemanSystemPrompt(): string {
	try {
		return readFileSync(CAVEMAN_SKILL_PATH, "utf-8");
	} catch {
		return "Respond terse like smart caveman. All technical substance stay. Only fluff die.";
	}
}

export default function (pi: ExtensionAPI) {
	let installNotified = false;
	let autoEnabled = true;
	let activated = false;

	// Auto-enable caveman once on first user message
	pi.on("before_agent_start", async (event, ctx) => {
		if (!autoEnabled || activated) return;

		const userMessage = event.prompt?.trim().toLowerCase() ?? "";

		// Check if first message is explicitly turning caveman off
		if (userMessage === "/caveman off") {
			autoEnabled = false;
			activated = true;
			return;
		}

		activated = true;

		if (!isCavemanInstalled()) {
			if (!installNotified) {
				installNotified = true;
				ctx.ui.notify(
					"💡 Caveman skill not installed. Run: git clone " + CAVEMAN_REPO_URL + " ~/.pi/agent/skills/caveman",
					"info",
					{ timeout: 15000 },
				);
			}
			return;
		}

		// If user invoked a skill/command via /, append caveman to system prompt
		// instead of injecting a competing user message that overrides the skill
		if (userMessage.startsWith("/")) {
			return {
				systemPrompt: event.systemPrompt + "\n\n" + getCavemanSystemPrompt(),
			};
		}

		// Normal first message: inject trigger message so caveman skill auto-loads
		return {
			message: {
				customType: "auto-caveman",
				content: "caveman mode",
				display: false,
			},
		};
	});

	// Manual toggle command
	pi.registerCommand("caveman", {
		description: "Toggle caveman auto-mode or set level: /caveman [on|off|lite|full|ultra]",
		handler: async (args, ctx) => {
			const arg = args.trim().toLowerCase();

			if (!isCavemanInstalled()) {
				ctx.ui.notify("❌ Caveman skill not installed. Run: git clone " + CAVEMAN_REPO_URL + " ~/.pi/agent/skills/caveman", "error");
				return;
			}

			switch (arg) {
				case "":
				case "status":
					ctx.ui.notify(`Caveman auto-mode: ${autoEnabled ? "ON" : "OFF"}`, "info");
					break;
				case "on":
					autoEnabled = true;
					ctx.ui.notify("✅ Caveman auto-mode enabled", "success");
					break;
				case "off":
					autoEnabled = false;
					ctx.ui.notify("⏹️  Caveman auto-mode disabled", "success");
					break;
				case "lite":
				case "full":
				case "ultra":
				case "wenyan-lite":
				case "wenyan-full":
				case "wenyan-ultra":
					// Send immediate caveman command with level
					pi.sendUserMessage(`/caveman ${arg}`);
					break;
				default:
					ctx.ui.notify("Usage: /caveman [on|off|lite|full|ultra|wenyan-lite|wenyan-full|wenyan-ultra]", "warning");
			}
		},
	});

}

