# pstack in dotfiles

The complete [Lauren Tan pstack package](https://github.com/cursor/plugins/tree/main/pstack) is vendored in `agents/pstack/`. Snapshot `2eb7ed4613cfc8f098dfe464a23680ea44d84c5e`, version `0.15.5`, retrieved 2026-09-30. The upstream MIT license is retained.

The package includes 47 skills, 23 playbooks, 23 engineering principles, two agent definitions, the guide, references, assets, plugin metadata, and the dormant Benny automation pack. The principles are part of the 47 skills, not additional skills.

## Install and start

After updating your dotfiles checkout, run its normal installer. Both `agents/install.zsh` and `agents/install.ps1` discover the existing personal skills and the bundled pstack skills. They link each into `~/.agents/skills`, `~/.claude/skills`, `~/.cursor/skills`, and `~/.gemini/skills`. The two agent definitions are linked into the Cursor and Claude user agent directories. Existing personal skill sources remain in `agents/skills/`.

In the target coding tool, run `setup-pstack` to select available models and a budget. Then invoke `poteto-mode` with a concrete task and a checkable outcome. Use the tool's native skill invocation syntax; slash commands vary between tools. The mode is opt-in. Models are configured in the target session, not preselected in these dotfiles.

Example task: use poteto-mode to reproduce a retry that duplicates export rows, fix its root cause, and demonstrate failing-before and passing-after evidence.

## Compatibility and dependencies

Every installed skill links to [HARNESS.md](pstack/HARNESS.md). That contract maps project-local skill paths, model configuration, questions, delegation, and verification to the active tool's actual capabilities. It explicitly preserves user permissions and marks unavailable independent review or runtime proof as blocked.

Cursor is the upstream native environment. Other tools can discover the skills, but multi-model delegation, custom agents, session pickup, and automation depend on their capabilities. Installation checks do not establish end-to-end parity across tools.

The separately distributed `cursor-team-kit` supplies `deslop`, `control-cli`, and `control-ui`. Install it in Cursor when those dependencies are needed, or establish supported equivalents in another tool. It is not included in the pstack snapshot. Benny is retained as source and remains inactive; no scheduled tasks, Slack connections, or bot credentials are created by the dotfiles installer.

## Local changes and updates

- Add a compatibility-contract pointer after each top-level skill and agent's frontmatter.
- Normalize the two display-style skill names to `poteto-mode` and `make-bot-ui` so their names match their folders.
- Add `HARNESS.md`; preserve upstream playbooks, references, guide text, and automation files. Five guide illustrations use pinned upstream URLs; the logo and design illustration are bundled locally.
- Extend the two dotfiles installers to link the package's skills and agent definitions.

To refresh, replace the vendored package from a reviewed upstream snapshot, reapply the compatibility pointers and name normalization, and update the recorded snapshot and version. Validate all skill metadata, relative resources, plugin paths, and installer behavior before shipping the update.
