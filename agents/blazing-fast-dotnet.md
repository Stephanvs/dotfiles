# Blazing Fast .NET in dotfiles

The `blazing-fast-dotnet` skill from [Egor Bogatov's BlazingFastDotnet](https://github.com/EgorBo/BlazingFastDotnet) is vendored in `agents/blazing-fast-dotnet/`. Pinned commit `b2cb3ba4ee689e3e012a93d680d4de19335b8003`, retrieved 2026-10-26. The upstream MIT license is retained as `LICENSE`.

The snapshot contains the upstream `SKILL.md` at `skills/blazing-fast-dotnet/SKILL.md`, copied byte for byte with no local edits.

## Install

After updating your dotfiles checkout, run its normal installer. Both `agents/install.zsh` and `agents/install.ps1` discover this skill alongside the existing personal and vendored skills. They link it into `~/.agents/skills`, `~/.claude/skills`, `~/.cursor/skills`, and `~/.gemini/skills`.

Invoke `blazing-fast-dotnet` when profiling or optimizing a .NET workload. Upstream recommends using it on demand, measuring a baseline, and keeping only changes with a measurable improvement.

## Refresh

To refresh, replace `LICENSE` and `skills/blazing-fast-dotnet/SKILL.md` from a reviewed upstream commit, then update the pinned commit and retrieval date above. Confirm that the skill name does not collide with another skill discovered by either installer.
