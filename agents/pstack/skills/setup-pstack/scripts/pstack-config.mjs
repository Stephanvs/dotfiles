#!/usr/bin/env node
// Validate and render the pstack model configuration against capabilities the
// active tool reports. Role labels and defaults come from ../SKILL.md step 5;
// model IDs, efforts, and history modes come only from the capabilities file.
// Each runtime reads and writes only its own file (RUNTIMES, mirrored in HARNESS.md).
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import process from "node:process";
import { fileURLToPath, pathToFileURL } from "node:url";

const SKILL = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "SKILL.md");
export const ALIASES = ["inherit-parent", "auto"];
export const PANELS = ["arena runners", "arena cross-judge pool", "architect runners", "interrogate reviewers"];
export const LADDER = ["low", "medium", "high", "xhigh", "max"];
export const BUDGETS = { unlimited: "max", large: "xhigh", medium: "high", small: "medium" };
export const RUNTIMES = {
	cursor: { file: [".cursor", "rules", "pstack-models.mdc"], format: "cursor" },
	claude: { file: [".claude", "rules", "pstack-models.md"], format: "markdown" },
	gemini: { file: [".gemini", "pstack-models.md"], format: "markdown" },
	codex: { file: [".agents", "pstack-models", "codex.md"], format: "markdown", legacy: true },
	opencode: { file: [".agents", "pstack-models", "opencode.md"], format: "markdown", legacy: true },
	grok: { file: [".agents", "pstack-models", "grok.md"], format: "markdown", legacy: true },
};
export const LEGACY_SHARED = [".agents", "pstack-models.md"];
const ENTRY_KEYS = ["effort", "history"];
const HEADER = [
	"# pstack model configuration. One line per role. Delete a line to fall back to the skill default.",
	"# `inherit-parent` or `auto` as a value: the role runs on the parent chat model (omit Task `model`). Alias entries in a panel list still count toward its fan-out.",
];
const FIELDS_NOTE =
	"# `effort=` and `history=` after a model: pass them as the runtime's separate reasoning-effort and history-mode settings. Omit any setting a line does not name.";
const FRONTMATTER = [
	"---",
	"description: pstack per-role model choices (overrides skill defaults)",
	"alwaysApply: true",
	"---",
];

export class ConfigError extends Error {}

const isAlias = (model) => ALIASES.includes(model);

export function parseEntry(text, where) {
	const [model, ...rest] = text.trim().split(/\s+/);
	if (!model) throw new ConfigError(`${where}: empty entry`);
	const entry = { model };
	for (const field of rest) {
		const match = field.match(/^([a-z]+)=(\S+)$/);
		if (!match || !ENTRY_KEYS.includes(match[1])) throw new ConfigError(`${where}: unknown setting "${field}"`);
		if (match[1] in entry) throw new ConfigError(`${where}: "${match[1]}" given twice`);
		entry[match[1]] = match[2];
	}
	return entry;
}

export function parseConfig(text, roles = defaultRoles()) {
	let lines = text.split(/\r?\n/);
	if (lines[0] === "---") lines = lines.slice(lines.indexOf("---", 1) + 1);
	const selection = { budget: null, roles: {} };
	const dropped = [];
	lines.forEach((raw, i) => {
		const line = raw.trim();
		const where = `line ${i + 1}`;
		const budget = line.match(/^# budget: (\S+)/);
		if (budget) {
			selection.budget = budget[1];
			return;
		}
		const runtime = line.match(/^# runtime: (\S+)$/);
		if (runtime) {
			selection.runtime = runtime[1];
			return;
		}
		if (line === "" || line.startsWith("#")) return;
		const split = line.indexOf(": ");
		if (split === -1) throw new ConfigError(`${where}: expected "<role>: <model>"`);
		const role = line.slice(0, split);
		if (roles && !roles.includes(role)) {
			dropped.push(line);
			return;
		}
		if (role in selection.roles) throw new ConfigError(`${where}: role "${role}" appears twice`);
		selection.roles[role] = line
			.slice(split + 2)
			.split(",")
			.map((part) => parseEntry(part, `${where} (${role})`));
	});
	return { ...selection, dropped };
}

export function defaultConfig(skillText = fs.readFileSync(SKILL, "utf8")) {
	const step = skillText.indexOf("### 5.");
	const open = skillText.indexOf("```\n", step);
	const close = skillText.indexOf("\n```", open + 4);
	if (step === -1 || open === -1 || close === -1) throw new ConfigError("SKILL.md step 5 has no fenced rule shape");
	const { dropped, ...selection } = parseConfig(skillText.slice(open + 4, close), null);
	return selection;
}

export function defaultRoles() {
	return Object.keys(defaultConfig().roles);
}

export function normalizeCapabilities(raw) {
	if (!raw || typeof raw !== "object") throw new ConfigError("capabilities must be a JSON object");
	if (!["slug", "separate"].includes(raw.modelField))
		throw new ConfigError('capabilities.modelField must be "slug" (effort is part of the model ID) or "separate"');
	if (!Array.isArray(raw.models) || raw.models.length === 0)
		throw new ConfigError("capabilities.models must list the models the active tool can delegate to");
	const models = new Map();
	for (const model of raw.models) {
		const id = typeof model === "string" ? model : model?.id;
		if (typeof id !== "string" || id === "") throw new ConfigError("every capabilities.models entry needs an id");
		if (isAlias(id)) throw new ConfigError(`capabilities.models must not list the alias "${id}"`);
		const efforts = typeof model === "string" ? [] : (model.efforts ?? []);
		if (!Array.isArray(efforts)) throw new ConfigError(`capabilities.models "${id}" efforts must be a list`);
		if (raw.modelField === "slug" && efforts.length)
			throw new ConfigError(
				`capabilities.models "${id}" lists efforts, but modelField "slug" encodes effort in the ID`,
			);
		models.set(id, efforts);
	}
	const historyModes = new Map();
	for (const mode of raw.historyModes ?? []) {
		if (typeof mode?.id !== "string") throw new ConfigError("every capabilities.historyModes entry needs an id");
		historyModes.set(mode.id, { model: mode.acceptsModel === true, effort: mode.acceptsEffort === true });
	}
	return { id: raw.runtime, runtime: raw.runtime ?? "this runtime", modelField: raw.modelField, models, historyModes };
}

export function validate(selection, caps, roles = defaultRoles()) {
	const errors = [];
	if (!(selection.budget in BUDGETS))
		errors.push(`budget "${selection.budget}" is not one of ${Object.keys(BUDGETS).join(", ")}`);
	for (const [role, entries] of Object.entries(selection.roles ?? {})) {
		if (!roles.includes(role)) {
			errors.push(`role "${role}" is not a pstack role`);
			continue;
		}
		if (!Array.isArray(entries) || entries.length === 0) {
			errors.push(`role "${role}" needs at least one entry`);
			continue;
		}
		if (!PANELS.includes(role) && entries.length !== 1)
			errors.push(`role "${role}" takes one model, got ${entries.length}`);
		entries.forEach((entry, i) => {
			const where = PANELS.includes(role) ? `role "${role}" entry ${i + 1}` : `role "${role}"`;
			for (const key of Object.keys(entry)) {
				if (key !== "model" && !ENTRY_KEYS.includes(key)) errors.push(`${where}: unknown setting "${key}"`);
			}
			const alias = isAlias(entry.model);
			if (alias && entry.effort !== undefined)
				errors.push(`${where}: "${entry.model}" keeps the parent's model and effort, so it cannot set effort`);
			if (!alias && !caps.models.has(entry.model))
				errors.push(`${where}: model "${entry.model}" is not offered by ${caps.runtime}`);
			if (entry.effort !== undefined && !alias) {
				if (caps.modelField === "slug")
					errors.push(`${where}: ${caps.runtime} encodes effort in the model ID, so effort cannot be set separately`);
				else if (caps.models.has(entry.model) && !caps.models.get(entry.model).includes(entry.effort))
					errors.push(`${where}: model "${entry.model}" does not offer effort "${entry.effort}"`);
			}
			if (entry.history !== undefined) {
				const mode = caps.historyModes.get(entry.history);
				if (!mode) errors.push(`${where}: history mode "${entry.history}" is not offered by ${caps.runtime}`);
				else {
					if (!alias && !mode.model)
						errors.push(
							`${where}: history mode "${entry.history}" inherits the parent model, so it cannot take model "${entry.model}"`,
						);
					if (entry.effort !== undefined && !mode.effort)
						errors.push(
							`${where}: history mode "${entry.history}" inherits the parent effort, so it cannot take effort "${entry.effort}"`,
						);
				}
			}
		});
	}
	return errors;
}

function slugEffort(slug) {
	const tokens = slug.split("-");
	const at = tokens.at(-1) === "fast" ? tokens.length - 2 : tokens.length - 1;
	if (at < 1 || !LADDER.includes(tokens[at])) return null;
	return { tokens, at, effort: tokens[at] };
}

function withEffort({ tokens, at }, effort) {
	return [...tokens.slice(0, at), effort, ...tokens.slice(at + 1)].join("-");
}

function bestAtOrBelow(efforts, target) {
	const limit = LADDER.indexOf(target);
	return LADDER.slice(0, limit + 1)
		.reverse()
		.find((effort) => efforts.includes(effort));
}

export function applyBudget(selection, caps, budget) {
	if (!(budget in BUDGETS))
		throw new ConfigError(`budget "${budget}" is not one of ${Object.keys(BUDGETS).join(", ")}`);
	const target = BUDGETS[budget];
	const needsChoice = [];
	const roles = {};
	for (const [role, entries] of Object.entries(selection.roles)) {
		roles[role] = entries.map((entry, i) => {
			if (budget === "unlimited" || isAlias(entry.model)) return { ...entry };
			const mark = (reason) => needsChoice.push({ role, entry: i + 1, model: entry.model, reason });
			if (entry.history !== undefined && caps.historyModes.get(entry.history)?.effort === false) return { ...entry };
			if (caps.modelField === "slug") {
				const parsed = slugEffort(entry.model);
				if (!parsed) return { ...entry };
				const wanted = withEffort(parsed, target);
				if (caps.models.has(wanted)) return { ...entry, model: wanted };
				const family = [...caps.models.keys()]
					.map(slugEffort)
					.filter((other) => other && withEffort(other, "") === withEffort(parsed, ""))
					.map((other) => other.effort);
				const fallback = bestAtOrBelow(family, target);
				if (fallback) return { ...entry, model: withEffort(parsed, fallback) };
				mark(`no offered ${withEffort(parsed, "*")} slug at or below ${target}`);
				return { ...entry, model: wanted };
			}
			if (!caps.models.has(entry.model)) {
				mark(`model is not offered by ${caps.runtime}`);
				return { ...entry };
			}
			const fallback = bestAtOrBelow(caps.models.get(entry.model), target);
			if (fallback) return { ...entry, effort: fallback };
			mark(`model offers no effort at or below ${target}`);
			return { ...entry };
		});
	}
	return { budget, roles, needsChoice };
}

const renderEntry = (entry) =>
	[entry.model, ...ENTRY_KEYS.filter((key) => entry[key] !== undefined).map((key) => `${key}=${entry[key]}`)].join(" ");

export function render(selection, format, roles = defaultRoles(), runtime = undefined) {
	if (!["cursor", "markdown"].includes(format)) throw new ConfigError('format must be "cursor" or "markdown"');
	const ordered = roles.filter((role) => role in selection.roles);
	const fields = ordered.some((role) =>
		selection.roles[role].some((entry) => ENTRY_KEYS.some((key) => entry[key] !== undefined)),
	);
	return [
		...(format === "cursor" ? FRONTMATTER : []),
		...HEADER,
		...(fields ? [FIELDS_NOTE] : []),
		...(runtime ? [`# runtime: ${runtime}`] : []),
		`# budget: ${selection.budget} (${BUDGETS[selection.budget]})`,
		...ordered.map((role) => `${role}: ${selection.roles[role].map(renderEntry).join(", ")}`),
		"",
	].join("\n");
}

const comparable = (selection, roles) =>
	JSON.stringify({
		runtime: selection.runtime,
		budget: selection.budget,
		roles: roles
			.filter((role) => role in selection.roles)
			.map((role) => [role, selection.roles[role].map(renderEntry)]),
	});

export function runtimeFile(runtime, home = os.homedir()) {
	if (!(runtime in RUNTIMES))
		throw new ConfigError(`runtime "${runtime}" is not one of ${Object.keys(RUNTIMES).join(", ")}`);
	return path.join(home, ...RUNTIMES[runtime].file);
}

function readExisting(file, roles) {
	try {
		return parseConfig(fs.readFileSync(file, "utf8"), roles);
	} catch (error) {
		if (error instanceof ConfigError)
			throw new ConfigError(`${file} is not a pstack model configuration: ${error.message}`);
		throw error;
	}
}

export function loadConfig(runtime, home = os.homedir(), roles = defaultRoles()) {
	const file = runtimeFile(runtime, home);
	if (fs.existsSync(file)) {
		const { runtime: owner, ...config } = readExisting(file, roles);
		if (owner !== undefined && owner !== runtime)
			throw new ConfigError(`${file} records runtime "${owner}", not "${runtime}"`);
		return { runtime, source: "runtime", file, ...config };
	}
	const legacy = path.join(home, ...LEGACY_SHARED);
	if (RUNTIMES[runtime].legacy && fs.existsSync(legacy)) {
		const { runtime: owner, ...config } = readExisting(legacy, roles);
		return { runtime, source: "legacy-shared", file, legacyFile: legacy, ...config };
	}
	return { runtime, source: "defaults", file, ...defaultConfig(), dropped: [] };
}

export function writeConfig(selection, caps, { runtime, home = os.homedir() }, roles = defaultRoles()) {
	const out = runtimeFile(runtime, home);
	if (caps.id !== undefined && caps.id !== runtime)
		return { written: false, errors: [`capabilities describe runtime "${caps.id}", not "${runtime}"`] };
	const errors = validate(selection, caps, roles);
	if (errors.length) return { written: false, out, errors };
	if (fs.existsSync(out)) {
		const owner = readExisting(out, roles).runtime;
		if (owner !== undefined && owner !== runtime)
			return { written: false, out, errors: [`${out} records runtime "${owner}", not "${runtime}"`] };
	}
	const expected = { ...selection, runtime };
	const text = render(expected, RUNTIMES[runtime].format, roles, runtime);
	const { dropped, ...readback } = parseConfig(text, roles);
	if (comparable(readback, roles) !== comparable(expected, roles))
		throw new ConfigError("rendered configuration does not parse back to the selection");
	if (fs.existsSync(out) && fs.readFileSync(out, "utf8") === text)
		return { written: false, unchanged: true, out, errors: [] };
	fs.mkdirSync(path.dirname(out), { recursive: true });
	const temp = `${out}.${process.pid}.tmp`;
	fs.writeFileSync(temp, text);
	fs.renameSync(temp, out);
	if (fs.readFileSync(out, "utf8") !== text)
		throw new ConfigError(`readback of ${out} does not match what was written`);
	return { written: true, out, errors: [] };
}

const RUNTIME_NAMES = Object.keys(RUNTIMES).join("|");
const USAGE = `usage:
  pstack-config.mjs path --runtime <${RUNTIME_NAMES}>
  pstack-config.mjs load --runtime <${RUNTIME_NAMES}>
  pstack-config.mjs defaults
  pstack-config.mjs parse <config-file>
  pstack-config.mjs budget --capabilities <caps.json> --selection <selection.json> --budget <unlimited|large|medium|small>
  pstack-config.mjs validate --capabilities <caps.json> --selection <selection.json>
  pstack-config.mjs write --runtime <${RUNTIME_NAMES}> --capabilities <caps.json> --selection <selection.json>`;

function options(args) {
	const result = {};
	for (let i = 0; i < args.length; i += 2) {
		if (!args[i].startsWith("--") || args[i + 1] === undefined) throw new ConfigError(USAGE);
		result[args[i].slice(2)] = args[i + 1];
	}
	return result;
}

const readJson = (file, label) => {
	if (!file) throw new ConfigError(`missing --${label}\n${USAGE}`);
	try {
		return JSON.parse(fs.readFileSync(file, "utf8"));
	} catch (error) {
		throw new ConfigError(`cannot read ${label} ${file}: ${error.message}`);
	}
};

export function main(argv) {
	const [command, ...rest] = argv;
	const print = (value) => process.stdout.write(`${JSON.stringify(value, null, 2)}\n`);
	if (command === "defaults") return (print(defaultConfig()), 0);
	if (command === "parse") {
		if (!rest[0]) throw new ConfigError(USAGE);
		return (print(parseConfig(fs.readFileSync(rest[0], "utf8"))), 0);
	}
	if (!["path", "load", "budget", "validate", "write"].includes(command)) throw new ConfigError(USAGE);
	const opts = options(rest);
	if (command === "path") return (process.stdout.write(`${runtimeFile(opts.runtime ?? fail("--runtime"))}\n`), 0);
	if (command === "load") return (print(loadConfig(opts.runtime ?? fail("--runtime"))), 0);
	const caps = normalizeCapabilities(readJson(opts.capabilities, "capabilities"));
	const selection = readJson(opts.selection, "selection");
	if (command === "budget") return (print(applyBudget(selection, caps, opts.budget)), 0);
	const result =
		command === "validate"
			? { errors: validate(selection, caps) }
			: writeConfig(selection, caps, { runtime: opts.runtime ?? fail("--runtime") });
	for (const error of result.errors) process.stderr.write(`invalid: ${error}\n`);
	if (result.errors.length) {
		if (command === "write") process.stderr.write("nothing written; the existing configuration is unchanged\n");
		return 1;
	}
	if (command === "validate") process.stdout.write("valid\n");
	else process.stdout.write(result.unchanged ? `unchanged ${result.out}\n` : `wrote ${result.out}\n`);
	return 0;
}

function fail(flag) {
	throw new ConfigError(`missing ${flag}\n${USAGE}`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(fs.realpathSync(process.argv[1])).href) {
	try {
		process.exitCode = main(process.argv.slice(2));
	} catch (error) {
		if (!(error instanceof ConfigError)) throw error;
		process.stderr.write(`${error.message}\n`);
		process.exitCode = 2;
	}
}
