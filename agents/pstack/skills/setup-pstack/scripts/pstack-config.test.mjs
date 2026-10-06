import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { test } from "node:test";
import { fileURLToPath } from "node:url";
import {
	LEGACY_SHARED,
	RUNTIMES,
	applyBudget,
	defaultConfig,
	loadConfig,
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

const tempHome = () => fs.mkdtempSync(path.join(os.tmpdir(), "pstack-config-"));
const tempFile = (name) => path.join(tempHome(), name);

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
	const home = tempHome();
	assert.equal(writeConfig(codexSelection(), separate, { runtime: "codex", home }).written, true);
	const out = path.join(home, ".agents", "pstack-models", "codex.md");
	const first = fs.readFileSync(out, "utf8");
	const { dropped, runtime, ...parsed } = parseConfig(first);
	assert.equal(runtime, "codex");
	assert.deepEqual(parsed, codexSelection());
	assert.equal(parsed.roles["arena runners"].length, 3);
	assert.deepEqual(writeConfig(parsed, separate, { runtime: "codex", home }), {
		written: false,
		unchanged: true,
		out,
		errors: [],
	});
	assert.equal(fs.readFileSync(out, "utf8"), first);
});

test("invalid combinations fail before replacing an existing configuration", () => {
	const home = tempHome();
	const out = path.join(home, ".agents", "pstack-models", "codex.md");
	fs.mkdirSync(path.dirname(out), { recursive: true });
	fs.writeFileSync(out, "# budget: small (medium)\nbug-fix: model-b\n");
	const before = fs.readFileSync(out, "utf8");
	const bad = codexSelection();
	bad.roles["bug-fix"] = [{ model: "model-a", history: "fork" }];
	const run = (selection) =>
		spawnSync(
			process.execPath,
			[SCRIPT, "write", "--runtime", "codex", "--capabilities", capsFile(), "--selection", jsonFile(selection)],
			{ encoding: "utf8", env: { ...process.env, HOME: home } },
		);
	const result = run(bad);
	assert.equal(result.status, 1);
	assert.match(result.stderr, /inherits the parent model/);
	assert.equal(fs.readFileSync(out, "utf8"), before);
	const ok = run(codexSelection());
	assert.equal(ok.status, 0, ok.stderr);
	assert.match(
		fs.readFileSync(out, "utf8"),
		/^arena runners: model-a effort=high history=fresh, model-b effort=medium, auto$/m,
	);
});

test("configuring runtime A, then B, then A keeps both runtimes' choices", () => {
	const home = tempHome();
	const grokCaps = normalizeCapabilities({
		runtime: "grok",
		modelField: "slug",
		models: ["grok-x-high", "grok-x-low"],
	});
	const grokSelection = { budget: "large", roles: { "bug-fix": [{ model: "grok-x-high" }] } };
	const codexChanged = codexSelection();
	codexChanged.roles["swarm workers"] = [{ model: "model-b", effort: "low" }];

	writeConfig(codexSelection(), separate, { runtime: "codex", home });
	writeConfig(grokSelection, grokCaps, { runtime: "grok", home });
	const grokFile = fs.readFileSync(path.join(home, ".agents", "pstack-models", "grok.md"), "utf8");
	writeConfig(codexChanged, separate, { runtime: "codex", home });

	assert.equal(fs.readFileSync(path.join(home, ".agents", "pstack-models", "grok.md"), "utf8"), grokFile);
	const {
		runtime: codexOwner,
		dropped: d1,
		...codexParsed
	} = parseConfig(fs.readFileSync(path.join(home, ".agents", "pstack-models", "codex.md"), "utf8"));
	const { runtime: grokOwner, dropped: d2, ...grokParsed } = parseConfig(grokFile);
	assert.deepEqual([codexOwner, grokOwner], ["codex", "grok"]);
	assert.deepEqual(codexParsed, codexChanged);
	assert.deepEqual(grokParsed, grokSelection);
	assert.equal(loadConfig("grok", home).source, "runtime");
	assert.deepEqual(loadConfig("codex", home).roles, codexChanged.roles);
	assert.equal(fs.existsSync(path.join(home, ".agents", "pstack-models.md")), false);
});

test("a legacy shared file is offered, never attributed or rewritten", () => {
	const home = tempHome();
	const legacy = path.join(home, ".agents", "pstack-models.md");
	fs.mkdirSync(path.dirname(legacy), { recursive: true });
	const legacyText = "# budget: medium (high)\nbug-fix: model-a effort=high\n";
	fs.writeFileSync(legacy, legacyText);

	const offered = loadConfig("codex", home);
	assert.equal(offered.source, "legacy-shared");
	assert.equal(offered.legacyFile, legacy);
	assert.deepEqual(offered.roles, { "bug-fix": [{ model: "model-a", effort: "high" }] });
	assert.equal(loadConfig("cursor", home).source, "defaults");

	writeConfig(codexSelection(), separate, { runtime: "codex", home });
	assert.equal(fs.readFileSync(legacy, "utf8"), legacyText);
	assert.equal(loadConfig("codex", home).source, "runtime");
	assert.equal(loadConfig("grok", home).source, "legacy-shared");
});

test("a writer refuses another runtime's capabilities or file", () => {
	const home = tempHome();
	assert.deepEqual(writeConfig(codexSelection(), separate, { runtime: "grok", home }).errors, [
		'capabilities describe runtime "codex", not "grok"',
	]);
	const out = path.join(home, ".gemini", "pstack-models.md");
	fs.mkdirSync(path.dirname(out), { recursive: true });
	fs.writeFileSync(out, "# runtime: claude\n# budget: small (medium)\n");
	const gemini = normalizeCapabilities({ runtime: "gemini", modelField: "slug", models: ["gem-pro"] });
	const selection = { budget: "small", roles: { "bug-fix": [{ model: "gem-pro" }] } };
	assert.deepEqual(writeConfig(selection, gemini, { runtime: "gemini", home }).errors, [
		`${out} records runtime "claude", not "gemini"`,
	]);
	fs.writeFileSync(out, "unrelated notes\n");
	assert.throws(() => writeConfig(selection, gemini, { runtime: "gemini", home }), /not a pstack model configuration/);
	assert.equal(fs.readFileSync(out, "utf8"), "unrelated notes\n");
});

test("Cursor keeps its rule path and frontmatter", () => {
	const home = tempHome();
	const cursor = normalizeCapabilities({ runtime: "cursor", modelField: "slug", models: ["grok-4.7-xhigh-fast"] });
	writeConfig({ budget: "unlimited", roles: { "bug-fix": [{ model: "grok-4.7-xhigh-fast" }] } }, cursor, {
		runtime: "cursor",
		home,
	});
	const text = fs.readFileSync(path.join(home, ".cursor", "rules", "pstack-models.mdc"), "utf8");
	assert.match(text, /^---\ndescription: .*\nalwaysApply: true\n---\n/);
	assert.match(text, /^# runtime: cursor\n# budget: unlimited \(max\)\nbug-fix: grok-4.7-xhigh-fast\n$/m);
});

test("HARNESS.md documents the same runtime paths the writer uses", () => {
	const harness = fs.readFileSync(path.join(HERE, "..", "..", "..", "HARNESS.md"), "utf8");
	for (const [runtime, { file }] of Object.entries(RUNTIMES)) {
		assert.ok(harness.includes(`\`~/${file.join("/")}\``), `${runtime} path missing from HARNESS.md`);
	}
	assert.ok(harness.includes(`\`~/${LEGACY_SHARED.join("/")}\``));
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
