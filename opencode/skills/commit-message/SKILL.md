---
name: commit-message
description: Generate a conventional commit message from staged git changes. Use this skill when the user wants to create a commit message for their staged changes.
license: MIT
allowed-tools:
  - bash
metadata:
  version: "1.0"
---

# Commit Message Generator

This skill generates conventional commit messages from staged git changes.

## Usage

When invoked, analyze the staged changes and generate an appropriate commit message following the conventional commits specification.

## Process

1. First, check if there are staged changes:

```bash
git diff --cached
```

2. If there are staged changes, analyze them and generate a commit message.

3. The commit message should follow the conventional commits format:

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

## Commit Types

- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation only changes
- `style`: Changes that do not affect the meaning of the code (white-space, formatting)
- `refactor`: A code change that neither fixes a bug nor adds a feature
- `perf`: A code change that improves performance
- `test`: Adding missing tests or correcting existing tests
- `chore`: Changes to the build process or auxiliary tools and libraries
- `ci`: Changes to CI configuration files and scripts
- `revert`: Reverts a previous commit

## Guidelines

- Keep the subject line under 72 characters
- Use the imperative mood in the subject line ("add" not "added")
- Do not end the subject line with a period
- Separate subject from body with a blank line
- Use the body to explain what and why vs. how
- The scope is optional but helpful for larger projects

## Output

Output ONLY the commit message - no explanations, no markdown formatting, no code blocks, no quotes around the message. The message should be ready to use directly with `git commit -m`.
