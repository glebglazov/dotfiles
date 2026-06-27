import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { homedir } from "node:os";
import { fileURLToPath } from "node:url";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Sync pi's active theme to macOS appearance.
// Writes a JSON blob to ~/.pi/agent/themes/dynamic.json whose content
// matches pi's bundled `dark` or `light` builtin. Pi's hot-reload watcher
// on dynamic.json picks up the change and repaints the TUI.

const THEMES_DIR = join(homedir(), ".pi", "agent", "themes");
const DYNAMIC = join(THEMES_DIR, "dynamic.json");

let last: "dark" | "light" | null = null;

function findBuiltinThemePath(name: "dark" | "light"): string | null {
	// Primary: process.argv[1] is pi's entry (dist/cli.js).
	const entry = process.argv[1];
	if (entry) {
		const candidate = join(dirname(entry), "modes", "interactive", "theme", `${name}.json`);
		if (existsSync(candidate)) return candidate;
	}
	// Fallback: walk up from this file looking for the package in node_modules.
	let dir = dirname(fileURLToPath(import.meta.url));
	for (let i = 0; i < 10; i++) {
		const candidate = join(
			dir,
			"node_modules",
			"@earendil-works",
			"pi-coding-agent",
			"dist",
			"modes",
			"interactive",
			"theme",
			`${name}.json`,
		);
		if (existsSync(candidate)) return candidate;
		const parent = dirname(dir);
		if (parent === dir) break;
		dir = parent;
	}
	return null;
}

const detect = (): "dark" | "light" => {
	try {
		return execFileSync("defaults", ["read", "-g", "AppleInterfaceStyle"], { encoding: "utf8" })
			.trim()
			.toLowerCase() === "dark"
			? "dark"
			: "light";
	} catch {
		// Key absent → light mode.
		return "light";
	}
};

const sync = () => {
	mkdirSync(THEMES_DIR, { recursive: true });
	const next = detect();
	if (next === last && existsSync(DYNAMIC)) return;
	const src = findBuiltinThemePath(next);
	if (!src) return;
	const content = JSON.parse(readFileSync(src, "utf8")) as { name: string; [k: string]: unknown };
	content.name = "dynamic";
	writeFileSync(DYNAMIC, JSON.stringify(content, null, 2) + "\n");
	last = next;
};

export default (pi: ExtensionAPI) => {
	pi.on("session_start", sync);
	pi.on("turn_start", sync);
};
