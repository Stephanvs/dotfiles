import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";
import {
	applyBudget,
	defaultConfig,
	normalizeCapabilities,
	parseConfig,
	render,
	validate,
	writeConfig,
} from "./pstack-config.mjs";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const SCRIPT = path.join(HERE, "pstack-config.mjs");

const separate = normalizeCapabilities({
	runtime: "codex",
	modelField: "separate",
	models: [
		{ id: "model-a", efforts: ["low", "medium", "high", "xhigh"] },
		{ id: "model-b", efforts: ["low", "medium"] },
		{ id: "model-c" },
	],
	historyModes: [
		{ id: "fresh", acceptsModel: true, acceptsEffort: true },
		{ id: "fork", acceptsModel: false, acceptsEffort: false },
	],
});

const slugs = normalizeCapabilities({
	runtime: "cursor",
	modelField: "slug",
	models: [
		"claude-opus-5-5-max",
		"claude-opus-5-5-medium",
		"grok-4.7-xhigh-fast",
		"grok-4.7-medium-fast",
		"gpt-5.6-sol-max",
		"gpt-5.6-sol-low",
	],
});

const codexSelection = () => ({
	budget: "medium",
	roles: {
		"bug-fix": [{ model: "model-a", effort: "high" }],
		"judgment and prose": [{ model: "inherit-parent", history: "fork" }],
		"arena runners": [
			{ model: "model-a", effort: "high", history: "fresh" },
			{ model: "model-b", effort: "medium" },
			{ model: "auto" },
		],
		"swarm workers": [{ model: "model-c" }],
	},
});

const tempFile = (name = "pstack-models.md") =>
	path.join(fs.mkdtempSync(path.join(os.tmpdir(), "pstack-config-")), name);

test("default Cursor render reproduces the SKILL.md rule shape", () => {
	const skill = fs.readFileSync(path.join(HERE, "..", "SKILL.md"), "utf8");
	const block = skill.slice(skill.indexOf("```\n", skill.indexOf("### 5.")) + 4);
	assert.equal(render(defaultConfig(), "cursor"), block.slice(0, block.indexOf("```")));
});

test("separate model and effort fields validate independently", () => {
	assert.deepEqual(validate(codexSelection(), separate), []);
	const bad = codexSelection();
	bad.roles["bug-fix"] = [{ model: "model-b", effort: "xhigh" }];
	bad.roles["swarm workers"] = [{ model: "model-a-xhigh" }];
	bad.roles["hillclimb"] = [{ model: "model-c", effort: "low" }];
	assert.deepEqual(validate(bad, separate), [
		'role "bug-fix": model "model-b" does not offer effort "xhigh"',
		'role "swarm workers": model "model-a-xhigh" is not offered by codex',
		'role "hillclimb": model "model-c" does not offer effort "low"',
	]);
});

test("slug runtimes reject a separate effort setting", () => {
	const selection = { budget: "unlimited", roles: { "bug-fix": [{ model: "grok-4.7-xhigh-fast", effort: "high" }] } };
	assert.deepEqual(validate(selection, slugs), [
		'role "bug-fix": cursor encodes effort in the model ID, so effort cannot be set separately',
	]);
});

test("history modes that inherit parent settings reject explicit overrides", () => {
	const selection = {
		budget: "unlimited",
		roles: {
			"bug-fix": [{ model: "model-a", history: "fork" }],
			hillclimb: [{ model: "inherit-parent", history: "fork" }],
			"perf-issue": [{ model: "model-a", effort: "low", history: "fork" }],
			"how explorer": [{ model: "model-a", history: "rewind" }],
		},
	};
	assert.deepEqual(validate(selection, separate), [
		'role "bug-fix": history mode "fork" inherits the parent model, so it cannot take model "model-a"',
		'role "perf-issue": history mode "fork" inherits the parent model, so it cannot take model "model-a"',
		'role "perf-issue": history mode "fork" inherits the parent effort, so it cannot take effort "low"',
		'role "how explorer": history mode "rewind" is not offered by codex',
	]);
});

test("aliases keep parent settings and never become model IDs", () => {
	const selection = { budget: "small", roles: { "bug-fix": [{ model: "auto", effort: "low" }] } };
	assert.deepEqual(validate(selection, separate), [
		'role "bug-fix": "auto" keeps the parent\'s model and effort, so it cannot set effort',
	]);
	const budgeted = applyBudget({ roles: { "bug-fix": [{ model: "inherit-parent" }] } }, separate, "small");
	assert.deepEqual(budgeted.roles["bug-fix"], [{ model: "inherit-parent" }]);
	assert.match(render({ budget: "small", roles: budgeted.roles }, "markdown"), /^bug-fix: inherit-parent$/m);
});

test("role shape, unknown roles, and budget labels are checked", () => {
	const selection = {
		budget: "huge",
		roles: {
			"bug-fix": [{ model: "model-a" }, { model: "model-b" }],
			"how critics": [{ model: "model-a" }],
			"arena runners": [],
		},
	};
	assert.deepEqual(validate(selection, separate), [
		'budget "huge" is not one of unlimited, large, medium, small',
		'role "bug-fix" takes one model, got 2',
		'role "how critics" is not a pstack role',
		'role "arena runners" needs at least one entry',
	]);
});

test("validation uses only the supplied capabilities", () => {
	const selection = { budget: "unlimited", roles: { "bug-fix": [{ model: "grok-4.7-xhigh-fast" }] } };
	assert.deepEqual(validate(selection, slugs), []);
	const other = normalizeCapabilities({ runtime: "grok", modelField: "slug", models: ["some-other-model"] });
	assert.deepEqual(validate(selection, other), ['role "bug-fix": model "grok-4.7-xhigh-fast" is not offered by grok']);
});

test("slug budgets rewrite the effort token, fall back within a family, or ask", () => {
	const { roles, needsChoice } = applyBudget(defaultConfig(), slugs, "small");
	assert.deepEqual(roles["bug-fix"], [{ model: "grok-4.7-medium-fast" }]);
	assert.deepEqual(roles["judgment and prose"], [{ model: "claude-opus-5-5-medium" }]);
	assert.deepEqual(roles["arena runners"], [
		{ model: "claude-opus-5-5-medium" },
		{ model: "gpt-5.6-sol-low" },
		{ model: "grok-4.7-medium-fast" },
	]);
	assert.deepEqual(needsChoice, []);
	const sparse = normalizeCapabilities({ runtime: "cursor", modelField: "slug", models: ["gpt-5.6-sol-max"] });
	const result = applyBudget({ roles: { "reflect tooling": [{ model: "gpt-5.6-sol-max" }] } }, sparse, "large");
	assert.deepEqual(result.roles["reflect tooling"], [{ model: "gpt-5.6-sol-xhigh" }]);
	assert.equal(result.needsChoice.length, 1);
});

test("separate-field budgets set the effort field and skip inheriting history", () => {
	const { roles, needsChoice } = applyBudget(
		{
			roles: {
				"bug-fix": [{ model: "model-a", effort: "low" }],
				hillclimb: [{ model: "model-b" }],
				"arena runners": [{ model: "model-a" }, { model: "inherit-parent", history: "fork" }, { model: "model-c" }],
			},
		},
		separate,
		"medium",
	);
	assert.deepEqual(roles["bug-fix"], [{ model: "model-a", effort: "high" }]);
	assert.deepEqual(roles.hillclimb, [{ model: "model-b", effort: "medium" }]);
	assert.deepEqual(roles["arena runners"], [
		{ model: "model-a", effort: "high" },
		{ model: "inherit-parent", history: "fork" },
		{ model: "model-c" },
	]);
	assert.deepEqual(needsChoice, [
		{ role: "arena runners", entry: 3, model: "model-c", reason: "model offers no effort at or below high" },
	]);
});

test("panel counts, role choices, and budget survive render and rerun", () => {
	const out = tempFile();
	assert.equal(writeConfig(codexSelection(), separate, { out, format: "markdown" }).written, true);
	const first = fs.readFileSync(out, "utf8");
	const { dropped, ...parsed } = parseConfig(first);
	assert.deepEqual(parsed, codexSelection());
	assert.equal(parsed.roles["arena runners"].length, 3);
	assert.deepEqual(writeConfig(parsed, separate, { out, format: "markdown" }), {
		written: false,
		unchanged: true,
		errors: [],
	});
	assert.equal(fs.readFileSync(out, "utf8"), first);
});

test("invalid combinations fail before replacing an existing configuration", () => {
	const out = tempFile();
	fs.writeFileSync(out, "existing\n");
	const bad = codexSelection();
	bad.roles["bug-fix"] = [{ model: "model-a", history: "fork" }];
	const result = spawnSync(
		process.execPath,
		[SCRIPT, "write", "--capabilities", capsFile(), "--selection", jsonFile(bad), "--out", out, "--format", "markdown"],
		{
			encoding: "utf8",
		},
	);
	assert.equal(result.status, 1);
	assert.match(result.stderr, /inherits the parent model/);
	assert.equal(fs.readFileSync(out, "utf8"), "existing\n");
	const ok = spawnSync(
		process.execPath,
		[
			SCRIPT,
			"write",
			"--capabilities",
			capsFile(),
			"--selection",
			jsonFile(codexSelection()),
			"--out",
			out,
			"--format",
			"markdown",
		],
		{
			encoding: "utf8",
		},
	);
	assert.equal(ok.status, 0, ok.stderr);
	assert.match(
		fs.readFileSync(out, "utf8"),
		/^arena runners: model-a effort=high history=fresh, model-b effort=medium, auto$/m,
	);
});

test("parse drops retired roles and reports them", () => {
	const parsed = parseConfig("# budget: small (medium)\nhow critics: model-a\nbug-fix: model-a effort=low\n");
	assert.deepEqual(parsed, {
		budget: "small",
		roles: { "bug-fix": [{ model: "model-a", effort: "low" }] },
		dropped: ["how critics: model-a"],
	});
});

function jsonFile(value) {
	const file = tempFile("value.json");
	fs.writeFileSync(file, JSON.stringify(value));
	return file;
}

function capsFile() {
	return jsonFile({
		runtime: "codex",
		modelField: "separate",
		models: [
			{ id: "model-a", efforts: ["low", "medium", "high", "xhigh"] },
			{ id: "model-b", efforts: ["low", "medium"] },
			{ id: "model-c" },
		],
		historyModes: [
			{ id: "fresh", acceptsModel: true, acceptsEffort: true },
			{ id: "fork", acceptsModel: false, acceptsEffort: false },
		],
	});
}
