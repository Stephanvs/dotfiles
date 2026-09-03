# Console Output, Provider Abstractions, Testing

- [Output vs logging](#output-vs-logging)
- [Spectre.Console patterns](#spectreconsole-patterns)
- [Provider abstraction pattern](#provider-abstraction-pattern)
- [Testing](#testing)

## Output vs logging

Two separate channels, never mixed:

| Channel | API | Audience |
|---|---|---|
| User-facing output | `AnsiConsole` (Spectre.Console) | The person at the terminal |
| Diagnostics | `ILogger<T>` -> Serilog file sink | Debugging after the fact |

An error path does **both**: `_logger.LogError(ex, "...")` for the stack trace, then one `AnsiConsole.MarkupLine($"[red]Error:[/] {ex.Message}")` for the user.

Commands own all `AnsiConsole` calls. Services log and return values; a service that prints cannot be tested or reused.

## Spectre.Console patterns

Semantic colour vocabulary, used consistently:

```csharp
AnsiConsole.MarkupLine("[red]Error:[/] Not in a git repository");
AnsiConsole.MarkupLine("[yellow]No worktrees found[/]");           // warning / empty state
AnsiConsole.MarkupLine($"[green]OK[/] Created worktree at {path}"); // success
AnsiConsole.MarkupLine("[dim]Running pre-create hook...[/]");       // progress chatter
```

Tabular results use `Table` with `TableBorder.Rounded`, bold headers, and a `[dim]` summary line:

```csharp
var table = new Table();
table.Border(TableBorder.Rounded);
table.AddColumn("[bold]Branch[/]");
table.AddColumn("[bold]Path[/]");
table.AddRow(branchDisplay, pathDisplay);
AnsiConsole.Write(table);
AnsiConsole.MarkupLine($"[dim]Total: {worktrees.Count} worktree(s)[/]");
```

Confirmations go through `AnsiConsole.Confirm(...)`, always guarded by the shared auto-confirm option, and a decline is exit code `0` (the user got what they asked for):

```csharp
if (!autoConfirm && !AnsiConsole.Confirm($"Create worktree at {worktreePath}?"))
{
    AnsiConsole.MarkupLine("[yellow]Cancelled[/]");
    return 0;
}
```

**Markup hazard:** interpolating user or filesystem strings into `MarkupLine` breaks on `[`. Use `AnsiConsole.WriteLine` or `Markup.Escape(value)` for untrusted text.

## Provider abstraction pattern

When a capability has many platform- or tool-specific implementations (terminals, editors, package managers), define a provider interface with **self-describing capability metadata** and let an orchestrating service pick:

```csharp
public interface ITerminalProvider
{
    string Name { get; }
    Platform SupportedPlatforms { get; }   // [Flags] enum
    int Priority { get; }                  // higher wins
    bool IsAvailable { get; }              // installed & runnable right now
    bool SupportsMode(TerminalMode mode);
    bool Open(string workingDirectory, TerminalMode mode, string? initCommand = null);
}
```

The service filters and ranks rather than switching on type:

```csharp
var candidates = _providers.Where(p => p.SupportsMode(mode) && p.IsAvailable).ToList();
// user's configured preference wins, else highest Priority
```

Supporting details that make this work:

- A lowest-`Priority` fallback provider that is always available (e.g. one that just echoes `cd <path>`), so the service degrades instead of failing.
- An alias map (`Dictionary<string, string[]>` with `StringComparer.OrdinalIgnoreCase`) translating user-friendly config values (`wt`, `code`, `iterm`) to provider `Name`s.
- Platform filtering at registration time (see `hosting.md`), so `IsAvailable` only has to answer "is it installed".

## Testing

xUnit v3 + FakeItEasy + AwesomeAssertions, in a sibling `tests/` project referencing `src/` via `dotnet add reference`.

```bash
dotnet test > /tmp/dotnet-test.txt 2>&1
grep -E "Failed|Passed|error" /tmp/dotnet-test.txt
```

Project setup:

- `<Using Include="Xunit"/>` in the csproj so test files need no `using Xunit;`.
- `[assembly: InternalsVisibleTo("tests")]` in `src/Properties/AssemblyInfo.cs` when internals need testing.
- `<ValidateExecutableReferencesMatchSelfContained>false</ValidateExecutableReferencesMatchSelfContained>` — required when the test project references a self-contained/RID-specific exe project, otherwise the build fails.

Conventions:

```csharp
[Trait("Area", "Terminal")]
[Trait("Category", "Unit")]
public class TerminalServiceTests
{
    private readonly ILogger<TerminalService> _logger = A.Fake<ILogger<TerminalService>>();
    private readonly IOptionsMonitor<TerminalConfig> _terminalConfig = A.Fake<IOptionsMonitor<TerminalConfig>>();

    // ctor sets A.CallTo(() => _terminalConfig.CurrentValue).Returns(new TerminalConfig());

    [Fact]
    public void OpenWorktree_WithMatchingProvider_CallsProviderOpen()
    {
        var provider = A.Fake<ITerminalProvider>();
        A.CallTo(() => provider.SupportsMode(TerminalMode.Tab)).Returns(true);
        A.CallTo(() => provider.IsAvailable).Returns(true);

        var result = CreateService([provider]).OpenWorktree("/test/path", TerminalMode.Tab);

        result.Should().BeTrue();
        A.CallTo(() => provider.Open("/test/path", TerminalMode.Tab, null)).MustHaveHappenedOnceExactly();
    }
}
```

- Two traits on every class: `Area` (feature) and `Category` (`Unit`/`Integration`), enabling focused runs via `dotnet test --filter Category=Unit`.
- Method names: `Method_Scenario_ExpectedResult`.
- A private `CreateService(...)` factory per test class keeps construction in one place as dependencies grow.
- Fake the *interfaces* (`ITerminalProvider`, `IOptionsMonitor<T>`, `ILogger<T>`); fake `IOptionsMonitor<T>.CurrentValue` to return a real config POCO rather than faking the POCO.
- Test services and pure helpers. Do not test `Command` classes — if a command has logic worth testing, it belongs in a service.
