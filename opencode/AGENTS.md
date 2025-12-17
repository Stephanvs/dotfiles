# Global OpenCode Rules

## Lazy Loading Instructions

When working on a project, load the relevant technology-specific guidelines on a need-to-know basis using the Read tool. Only load what's relevant to the current task.

### Technology-Specific Guidelines

- For .NET/C# projects (*.csproj, *.cs, *.sln): @rules/dotnet.md
- For TypeScript/JavaScript projects: @rules/typescript.md
- For Rust projects: @rules/rust.md
- For Go projects: @rules/go.md

### Detection Hints

Detect project type by looking for:
- `.csproj`, `.sln`, `.cs` files -> .NET project
- `package.json`, `tsconfig.json` -> TypeScript/Node project
- `Cargo.toml` -> Rust project
- `go.mod` -> Go project

Only read the relevant rules file when you first need to perform an action specific to that technology (building, adding dependencies, creating files, etc.).
