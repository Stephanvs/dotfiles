# Harness compatibility contract

Apply this contract when reading the bundled upstream skills, agents, and playbooks. The original toolkit targets Cursor. Preserve its engineering and proof requirements while using capabilities the active coding tool actually exposes. User instructions, repository policies, and tool permissions take precedence over the toolkit, including its autonomy guidance.

## Locate skills and state

Resolve named skills from the active tool's skill catalog or this package's sibling `skills/` directory. Resolve playbooks and references relative to the skill file, following symlinks to the canonical package when necessary. Do not assume a Cursor plugin cache exists.

Interpret project-local `.cursor/skills/` paths as the repository's established skill directory for the active tool. If there is none, use `.agents/skills/` for Codex/OpenCode/Grok, `.claude/skills/` for Claude Code, `.cursor/skills/` for Cursor, or `.gemini/skills/` for Gemini. Keep generated verification skills and their feature maps together in that directory.

Interpret `~/.cursor/rules/pstack-models.mdc` references as the active tool's pstack model configuration file. Use that original path in Cursor, `~/.claude/rules/pstack-models.md` in Claude Code, `~/.gemini/pstack-models.md` in Gemini, or `~/.agents/pstack-models.md` in Codex/OpenCode/Grok. Read the file explicitly at each task start; automatic rule loading is not assumed. Outside Cursor, write the same budget and role labels in plain Markdown without Cursor's `alwaysApply` frontmatter. Do not overwrite an unrelated config or rule file.

## Use actual capabilities

- Map `Read`, `Glob`, `Grep`, shell, editing, to-do, and `AskQuestion` operations to the corresponding native tools. Ask an ordinary question when a structured question tool is unavailable. Do not invent a returned answer or approval.
- Enumerate available model choices from the active tool before configuration or delegation. Upstream slugs are examples, not evidence of availability. Only configure confirmed models or the supported `inherit-parent`/`auto` aliases. Never encode a reasoning budget by guessing an unavailable model slug. If a budget cannot be expressed by the tool, explain that limit during setup.
- When the tool takes model, reasoning effort, and history mode as separate delegation settings, keep them separate. A configured entry such as `<model> effort=high history=<mode>` means: pass the model ID, the effort, and the history mode through the matching native settings, and omit any setting the entry does not name. A history mode that inherits the parent conversation keeps the parent's model and effort, so do not combine it with explicit overrides. `setup-pstack` validates these combinations with `skills/setup-pstack/scripts/pstack-config.mjs` against the capabilities the tool reports.
- Map `Task`, background workers, custom subagent types, and read-only review to native delegation only when supported. Load the bundled agent definition into the delegate's instructions when custom type registration is unavailable. Carry the same scope, source pointers, isolation, and verification requirements.
- Do not claim multi-model review when only one model was used. If delegation is unavailable, execute independent slices sequentially when the playbook permits it, and label the review as single-agent. If an independent verdict is a required gate, report it as blocked rather than treating self-review as equivalent.
- Use the active tool's session/history interfaces. Cursor transcript paths and resume APIs are not portable. Read only task-relevant history authorized in the current session; never scan unrelated chats.
- Interpret Cursor's built-in `create-skill` as the available skill-authoring capability. This dotfiles repository already includes `skill-creator`.

## Preserve proof and authorization

Use an existing project harness or a supported browser, PTY, CLI, or HTTP tool to exercise real behavior. A missing driver is a verification blocker until a working equivalent is established. Compilation, a delegate's report, and an unexecuted generated skill are insufficient proof.

The external `cursor-team-kit` plugin supplies `deslop`, `control-cli`, and `control-ui`. It is not bundled here. In Cursor, install it with `/add-plugin cursor-team-kit` when those skills are needed. In another tool, use a demonstrated equivalent or report the specific missing capability. Do not claim that dependency is installed or that its check passed without evidence.

Do not use the toolkit's autonomy language as authorization to send messages, modify unrelated systems, merge, deploy, delete data, or bypass required approvals. Follow the user's actual scope and the host tool's permission rules. Keep automated Slack/Benny workflows dormant unless the user explicitly requests their configuration and activation.

Installing these files makes the instructions discoverable. It does not prove every workflow runs in every tool, configure model access, or activate the mode automatically. Enter `poteto-mode` explicitly and run `setup-pstack` in the target tool before relying on model-specific workflows.
