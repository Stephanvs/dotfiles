---
name: bevy-game-dev
description: Bevy game development guidance for Rust/Bevy projects, covering ECS architecture, system scheduling, events, helper utilities, project structuring, and build/performance profiles. Use when designing, reviewing, or refactoring Bevy game code; adding systems/components/resources; organizing plugins and states; or tuning build and release workflows.
---

# Bevy Game Dev

## Overview
Use this skill to apply Bevy best practices when designing or reviewing game architecture, ECS patterns, scheduling, and build profiles.

## Workflow
1. Clarify the task goal (feature, refactor, performance, build pipeline).
2. Identify Bevy version, states, and existing module/plugin layout.
3. Apply ECS patterns for entities, IDs, and helper utilities.
4. Define system scheduling with state bounds, sets, and explicit ordering.
5. Validate project structure (prelude, internal plugins, system grouping).
6. Adjust build and performance settings when needed.

## References
- Read `references/bevy-best-practices.md` for patterns, snippets, and build profile blocks.
- Use the reference as the canonical source for recommendations.

## Output Guidance
- Provide stepwise changes or concrete snippets tailored to the user’s codebase.
- Call out ordering dependencies between systems, sets, and events.
- When touching build profiles, include the exact `Cargo.toml` blocks and commands.
