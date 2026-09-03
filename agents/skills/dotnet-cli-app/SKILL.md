---
name: dotnet-cli-app
description: Build and extend .NET command-line tools using System.CommandLine, Generic Host DI, layered IConfiguration, Spectre.Console output, and Serilog file logging, packaged as a `dotnet tool` with self-contained RID binaries. Use when creating a new .NET CLI, adding or refactoring commands/options/arguments, wiring services or configuration into a console app, choosing console output or logging approaches, testing CLI services, or setting up packaging and release of a .NET CLI.
---

# .NET CLI App

Conventions for .NET console tools built on System.CommandLine v2 + `Host.CreateApplicationBuilder`. Reference implementation: `hypr` (E:\Code\hypr).

## Architecture

Five layers, each with one job:

| Layer | Location | Responsibility |
|---|---|---|
| Composition root | `Program.cs` | Build config, build host, assemble `RootCommand`, parse, invoke |
| DI registration | `Module.cs` | One `AddServices` extension chaining all registrations |
| Commands | `Commands/*Command.cs` | Parse-to-action glue; one class per verb, subclassing `Command` |
| Services | `Services/*Service.cs` | All domain work; no `System.CommandLine` types |
| Configuration | `Configuration/*Config.cs` | POCOs bound to config sections via `IOptionsMonitor<T>` |

**Rule:** commands own no logic beyond reading parsed values, calling services, and rendering results. Services never reference `ParseResult`, `Command`, or `AnsiConsole` — this is what makes them unit-testable.

## Workflow

1. Identify the verb and its aliases; create `Commands/<Verb>Command.cs`.
2. Declare `Argument<T>`/`Option<T>` as private properties; `Add(...)` them in the constructor; `SetAction(Execute)` last.
3. Inject services and `IOptionsMonitor<TConfig>` via constructor.
4. Register in `Module.AddCommands()` as `.AddSingleton<Command, XCommand>()`.
5. Put real work in a service; unit-test the service, not the command.
6. Return `0` success / `1` failure from the action; wrap the body in try/catch that logs and prints.

## References

Read the relevant file rather than guessing API shapes:

- `references/commands.md` — command/option/argument patterns, aliases, defaults from config, action signatures, `RootCommand` assembly.
- `references/hosting.md` — configuration precedence, DI registration, Scrutor assembly scanning, Serilog setup, platform paths.
- `references/output-and-testing.md` — Spectre.Console vs logging split, provider abstraction pattern, xUnit v3 + FakeItEasy test conventions.
- `references/packaging.md` — `PackAsTool`, RID-specific self-contained publishing, trimming, source-generated JSON, AOT-safety.

## Non-negotiables

- Use the CLI for all project/package/reference changes (`dotnet add package`, `dotnet add reference`, `dotnet sln add`) — never hand-edit `.csproj` for these.
- Pipe build/test output to a file and grep it: `dotnet build > /tmp/dotnet-build.txt 2>&1`.
- `Nullable` and `ImplicitUsings` enabled; `net10.0`.
- Config POCOs have defaults on every property so a missing config file is a valid state.
