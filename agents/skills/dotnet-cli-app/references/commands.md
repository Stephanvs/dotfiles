# Commands, Options, Arguments

- [Command class shape](#command-class-shape)
- [Declaring inputs](#declaring-inputs)
- [Defaults sourced from configuration](#defaults-sourced-from-configuration)
- [Shared options](#shared-options)
- [Actions and exit codes](#actions-and-exit-codes)
- [Root command assembly](#root-command-assembly)

## Command class shape

One file per verb in `Commands/`. Subclass `Command`, pass name + description to `base`, take dependencies via constructor, add inputs, then `SetAction` last.

```csharp
public sealed class ListCommand : Command
{
  private readonly ILogger<ListCommand> _logger;
  private readonly GitService _gitService;

  public ListCommand(ILogger<ListCommand> logger, GitService gitService)
    : base("list", "List all worktrees in the current repository")
  {
    _logger = logger;
    _gitService = gitService;

    Aliases.Add("ls");

    SetAction(Execute);
  }

  private int Execute(ParseResult _) { /* ... */ }
}
```

Aliases are cheap and expected — give every verb the abbreviations a user would reach for (`switch` → `sw`, `checkout`, `co`, `goto`, `go`; `cleanup` → `cl`, `clean`, `prune`, `rm`, `delete`).

## Declaring inputs

Declare each `Argument<T>` / `Option<T>` as a **private property** so the action can read it back with `ctx.GetValue(...)`. Use object-initializer syntax for `Aliases`, `Description`, `Arity`.

```csharp
private Argument<string> BranchArgument { get; } =
    new("branch")
    {
        Arity = ArgumentArity.ExactlyOne,
        Description = "Branch name or path",
    };

private Option<string?> FromBranchOption { get; } =
    new("--from")
    {
        Aliases = { "-fb", "--from-branch" },
        Description = "Source branch/commit to create from"
    };

private Option<DirectoryInfo?> DirOption { get; } =
    new("--dir") { Description = "Custom directory path" };
```

Lean on the binder's type conversion: use `DirectoryInfo`/`FileInfo` for paths and `enum` types for modes (`Option<TerminalMode?>`), rather than parsing strings by hand. Enum options get value completion and validation for free.

Register them in the constructor, in the order they should appear in help:

```csharp
Add(BranchArgument);
Add(FromBranchOption);
Add(TerminalModeOption);
Add(AutoConfirmOption);
```

## Defaults sourced from configuration

An option whose default comes from config must be constructed **inside** the constructor (it needs the injected `IOptionsMonitor<T>`), using `DefaultValueFactory`:

```csharp
TerminalModeOption = new("--terminal")
{
    Aliases = { "-tm", "--term" },
    Description = "Terminal mode",
    DefaultValueFactory = _ => _terminalConfig.CurrentValue.Mode,
};
```

`DefaultValueFactory` is a lambda, so it is evaluated at parse time and picks up `reloadOnChange` config edits. Still re-read `CurrentValue` in the action for nullable options and coalesce: `ctx.GetValue(TerminalModeOption) ?? terminalConfig.Mode`.

## Shared options

Options reused across commands become their own class deriving from `Option<T>`:

```csharp
public class AutoConfirmOption : Option<bool>
{
  public AutoConfirmOption() : base("--yes")
  {
    Aliases.Add("-y");
    Aliases.Add("--skip");
    Required = false;
    Description = "Auto confirm actions, eg; branch creation, deletion, etc.";
    DefaultValueFactory = _ => false;
  }
}
```

Each command that needs it holds its own instance (`private AutoConfirmOption AutoConfirmOption { get; } = new();`) — option instances are not shareable across commands.

Global flags (e.g. `--debug`) are added to the `RootCommand` instead.

## Actions and exit codes

`SetAction` accepts `Func<ParseResult, int>` or `Func<ParseResult, Task<int>>`; pick the async overload only when the body actually awaits.

```csharp
private int Execute(ParseResult ctx)
{
    try
    {
        var branch = ctx.GetRequiredValue(BranchArgument);   // arguments / required options
        var from   = ctx.GetValue(FromBranchOption);         // optional -> may be null

        // ... call services ...
        return 0;
    }
    catch (Exception ex)
    {
        _logger.LogError(ex, "Failed to switch to worktree");
        AnsiConsole.MarkupLine($"[red]Error:[/] {ex.Message}");
        return 1;
    }
}
```

Rules:
- `GetRequiredValue` for arguments and required options; `GetValue` for optional ones.
- Read every parsed value at the top of the action, then work with locals.
- `0` = success (including a user-cancelled confirmation), `1` = failure.
- Every action body is wrapped in a try/catch that logs the exception **and** prints a short `[red]Error:[/]` line. The stack trace goes to the log file; the user sees one line.

## Root command assembly

`Program.cs` never names individual commands — it resolves them all from DI:

```csharp
var rootCommand = new RootCommand("hypr - Git worktree manager");
rootCommand.Options.Add(new DebugOption());

foreach (var cmd in host.Services.GetRequiredService<IEnumerable<Command>>())
{
    rootCommand.Subcommands.Add(cmd);
}

return await rootCommand.Parse(args).InvokeAsync();
```

Adding a command is therefore a one-line change in `Module.AddCommands()`.
