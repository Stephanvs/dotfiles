# Subagent Model Selection

When the user names a model, provider, or reasoning effort for a subagent or delegated task (for example "use Opus medium" or "one agent on Sonnet, one on GPT"), use exactly that. The user's words beat every configured default, including `pstack-models.md`. If the named model or effort is unavailable, say so and ask; never substitute another model.

`pstack-models.md` maps pstack roles (feature, bug-fix, arena runners, and so on) to models. Apply it only while running a pstack skill or playbook that asks for that role, and only for settings the user did not name. Outside pstack, a subagent with no model named runs on the parent chat model.

When the user asks for several agents on "different models" without naming them, ask which models to use rather than picking from the pstack panels.
