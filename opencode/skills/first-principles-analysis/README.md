# first-principles-analysis

A portable Agent Skill for structured first-principles reasoning.

## Why this package is structured this way

The core skill uses only the open Agent Skills fields that matter most for portability:

- `name`
- `description`

The main instructions live in `SKILL.md`. Longer, situational guidance is split into `references/` so skills-compatible agents can load only what they need.

## Contents

- `SKILL.md` — main skill instructions and trigger description
- `references/autonomous-agent-patterns.md` — extra guidance for tool use and autonomous execution
- `references/examples.md` — longer examples
- `evals/evals.json` — optional test prompts for iterative evaluation

## Installation

### Claude Code

Place this directory at either:

- `~/.claude/skills/first-principles-analysis/`
- `.claude/skills/first-principles-analysis/` inside a project

### Claude.ai custom skill upload

Upload the ZIP file containing this folder as the ZIP root.

## Optional Claude Code extension for isolated planning

If you want Claude Code to run the skill in an isolated subagent context, you can add these frontmatter fields to `SKILL.md`:

```yaml
context: fork
agent: Plan
```

Use that variant only when you specifically want the skill to run as a self-contained planning task. The portable version in this package omits Claude-specific extensions by default.

## Notes

- This skill is instruction-only on purpose. It does not bundle scripts because the task is primarily analytical rather than deterministic.
- The description is intentionally specific so autonomous agents can trigger it for the right class of problems.
