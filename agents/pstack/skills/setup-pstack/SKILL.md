---
name: setup-pstack
description: Configure which models pstack uses per role and at what reasoning budget. Detects your available models and writes an always-applied rule that overrides the skill defaults. Use for /setup-pstack, "configure pstack models", "pstack budget", or changing pstack's model choices.
---

Read [the harness compatibility contract](../../HARNESS.md) before applying these instructions.


# Setup pstack

Write `~/.cursor/rules/pstack-models.mdc`, an always-applied rule that sets pstack's model per role.

## Steps

### 1. Detect available models

Enumerate the model slugs you can pass to a `Task` subagent in this session. That is the dependable source. If Cursor also exposes a models API or CLI that lists the user's entitled models, prefer it for completeness. If you cannot detect any, ask the user to paste the slugs they have access to. Never write a real slug you have not confirmed is available. The aliases `inherit-parent` and `auto` are always valid even though they are not detected slugs.

Save what the tool reports as a capabilities JSON file for [`scripts/pstack-config.mjs`](scripts/pstack-config.mjs), a Node helper whose `scripts/` path is relative to this skill file. Set `modelField` to `slug` when the reasoning effort is part of the model ID, as in Cursor, or to `separate` when the delegation tool takes the model and the reasoning effort as separate settings. List each model under `models`, with its offered `efforts` when they are separate. If the delegation tool has history modes, list each under `historyModes` with `acceptsModel` and `acceptsEffort`. A mode that forks or inherits the parent conversation usually keeps the parent's model and effort, so both are `false`. Set `runtime` to the active tool's name: `cursor`, `claude`, `gemini`, `codex`, `opencode`, or `grok`. Record only what the tool reports, never upstream example names. Example: `{"runtime": "codex", "modelField": "separate", "models": [{"id": "<model>", "efforts": ["low", "medium", "high"]}], "historyModes": [{"id": "<new>", "acceptsModel": true, "acceptsEffort": true}, {"id": "<fork>", "acceptsModel": false, "acceptsEffort": false}]}`.

### 2. Load current state

The default role-to-model mapping is the rule shape shown in step 5 below. Run `node scripts/pstack-config.mjs load --runtime <name>` with the active tool's name. It reads only that tool's `~/.cursor/rules/pstack-models.mdc` equivalent from the harness contract and prints a selection JSON. With `source` `runtime`, treat its `budget` and role values as the current choices. With `source` `defaults`, start from those defaults. With `source` `legacy-shared`, the choices come from the older `~/.agents/pstack-models.md` that Codex, OpenCode, and Grok used to share. Show them and ask whether they were chosen for this tool. Use them only on yes, otherwise start from the defaults. Leave the shared file in place either way, since another tool may still rely on it. A line whose role is not in step 5, such as `how critics`, is from a retired role. `load` lists it under `dropped`. Drop it.

### 3. Budget, map, and confirm

**(a) Ask for a budget.** Prefer AskQuestion over free text. Offer these four options with these exact labels, and name the current budget when the rule records one.

- `unlimited — keep max`
- `large — xhigh reasoning`
- `medium — high reasoning`
- `small — medium reasoning`

**(b) Apply it.** Build the working table from the skill defaults, and on a re-run keep any role you changed by family, list, or alias (`inherit-parent`, `auto`). `unlimited` leaves every effort as in that table. `large`, `medium`, and `small` set the effort token of every real slug, panel entries included, to `xhigh`, `high`, or `medium`. The effort token is the last token, or the one before a trailing `fast`, on the ladder `max` > `xhigh` > `high` > `medium` > `low`. If the result is not a detected slug, use the same family's detected slug with the highest effort at or below the target, else mark the role as needing a choice. `inherit-parent` and `auto` do not change. So `small` turns `claude-opus-5-5-max` into `claude-opus-5-5-medium`, and `grok-4.7-xhigh-fast` into `grok-4.7-medium-fast`. When `modelField` is `separate`, leave the model ID alone and set the entry's `effort` to the target, or to the model's highest offered effort below it. Entries whose history mode keeps the parent's effort stay unchanged. `node scripts/pstack-config.mjs budget --capabilities <caps.json> --selection <selection.json> --budget <label>` applies both rules and lists entries under `needsChoice`.

**(c) Show the roles and confirm.** Show every role with its model, marking any real slug not in the detected set as needing a choice. Also list each line step 2 dropped. Ask whether to accept as-is or change specific roles, offering the detected models plus `inherit-parent` and `auto` (both mean: this role runs on the parent chat model, which is how Auto users stay on Auto) as the options. Prefer AskQuestion over free text. For panel roles (arena runners, architect runners, interrogate reviewers) the value is a list, and one subagent runs per entry, alias entries included, so the list length sets the count. `arena cross-judge pool` is also a list, but Arena selects one value from it whose model family differs from the parent's when possible. `swarm workers` is the default model for every worker unless a race or comparison assigns another model per arm.

### 4. Validate

Every real slug written must be in the detected set. `inherit-parent` and `auto` always pass, and they never carry an `effort`. With separate fields, the model ID and the effort are each checked against what the tool offers for that model. An entry's history mode must be offered and must accept any explicit model or effort the entry sets. Run `node scripts/pstack-config.mjs validate --capabilities <caps.json> --selection <selection.json>`. If it prints any `invalid:` line, stop and ask again for those roles.

### 5. Write the rule

Write `~/.cursor/rules/pstack-models.mdc` with `alwaysApply: true`, a `# budget` line with the chosen label and its target effort, and one line per role, using the same labels poteto-mode uses. Overwrite the whole file so re-runs stay idempotent. Write it with `node scripts/pstack-config.mjs write --runtime <name> --capabilities <caps.json> --selection <selection.json>`. It writes only the active tool's file, with Cursor's frontmatter in Cursor and plain Markdown elsewhere, and adds a `# runtime: <name>` line above `# budget`. It never touches the legacy shared file or another tool's file, and it refuses capabilities or an existing file that name a different runtime. It validates again and leaves an existing file untouched when anything is invalid. It replaces the file atomically and checks the readback. With separate fields, an entry renders as `<model> effort=<effort> history=<mode>`, naming only the settings chosen. Shape:

```
---
description: pstack per-role model choices (overrides skill defaults)
alwaysApply: true
---
# pstack model configuration. One line per role. Delete a line to fall back to the skill default.
# `inherit-parent` or `auto` as a value: the role runs on the parent chat model (omit Task `model`). Alias entries in a panel list still count toward its fan-out.
# budget: unlimited (max)
feature, refactoring: grok-4.7-xhigh-fast
bug-fix: grok-4.7-xhigh-fast
perf-issue: grok-4.7-xhigh-fast
hillclimb: grok-4.7-xhigh-fast
judgment and prose: claude-opus-5-5-max
hardest tasks: claude-opus-5-5-max
how explorer: grok-4.7-xhigh-fast
how explainer: claude-opus-5-5-max
why investigators: grok-4.7-xhigh-fast
why synthesizer: claude-opus-5-5-max
reflect tooling: gpt-5.6-sol-max
reflect judgment, divergent, synthesizer: claude-opus-5-5-max
arena runners: claude-opus-5-5-max, gpt-5.6-sol-max, grok-4.7-xhigh-fast
arena cross-judge pool: claude-opus-5-5-max, gpt-5.6-sol-max, grok-4.7-xhigh-fast
swarm workers: grok-4.7-xhigh-fast
architect runners: claude-opus-5-5-max, gpt-5.6-sol-max, grok-4.7-xhigh-fast
interrogate reviewers: claude-opus-5-5-max, gpt-5.6-sol-max, grok-4.7-xhigh-fast
```

### 6. Confirm

Tell the user the rule was written and that it applies to new sessions. Re-running this skill updates it.

### 7. Offer a verification skill (optional)

Check whether the project has a way to drive the real app for proof (a `verify-*` skill, or an existing harness). If not, offer once: "want a project-local verification skill, so agents can drive the app the way a user does and prove changes work? I can generate one with /create-verification-skill." On yes, invoke `/create-verification-skill` (resolves wherever pstack is installed: workspace, user, or plugin). On no, move on without pushing.
