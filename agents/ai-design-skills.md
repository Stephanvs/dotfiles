# ai-design-skills in dotfiles

Two skills from [Elaya's ai-design-skills](https://github.com/elayadesign/ai-design-skills) are vendored in `agents/ai-design-skills/`. Pinned commit `a2735a3eaf092eaaffb6dc17df25de33ef3bd048`, retrieved 2026-10-26. The upstream MIT license is retained as `LICENSE`.

The snapshot is `skills/landing-page-design/SKILL.md` and `skills/design-to-motion/SKILL.md`, copied byte for byte with no local edits.

## Install

After updating your dotfiles checkout, run its normal installer. Both `agents/install.zsh` and `agents/install.ps1` discover these skills alongside the existing personal skills and the bundled pstack skills. They link each into `~/.agents/skills`, `~/.claude/skills`, `~/.cursor/skills`, and `~/.gemini/skills`.

## Refresh

To refresh, replace `LICENSE` and the vendored `SKILL.md` files from a reviewed upstream commit, then update the pinned commit and retrieval date recorded above. Confirm the skill directory names still do not collide with other skills discovered by either installer before shipping the update.
