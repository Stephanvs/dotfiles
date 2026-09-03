# Hosting, Configuration, DI, Logging

- [Composition root](#composition-root)
- [Configuration precedence](#configuration-precedence)
- [Config POCOs](#config-pocos)
- [DI module](#di-module)
- [Assembly scanning with Scrutor](#assembly-scanning-with-scrutor)
- [Logging](#logging)
- [Platform paths](#platform-paths)

## Composition root

`Program.cs` is top-level statements and does exactly five things: build configuration, build the host, register logging + services, assemble the root command, parse & invoke.

```csharp
var configBuilder = new ConfigurationBuilder()
    .SetBasePath(Directory.GetCurrentDirectory())
    .AddJsonFile(PathProvider.GetGlobalConfigPath(), optional: true, reloadOnChange: true)
    .AddJsonFile("hypr.json", optional: true, reloadOnChange: true)
    .AddJsonFile(".hypr.json", optional: true, reloadOnChange: true)
    .AddEnvironmentVariables("HYPR_");

var configuration = configBuilder.Build();

var builder = Host.CreateApplicationBuilder(args);
builder.Configuration.AddConfiguration(configuration);
builder.Services.AddHyprLogging(args);
builder.Services.AddSingleton<IConfiguration>(configuration);
builder.Services.AddServices(builder.Configuration);

var host = builder.Build();
```

Use `Host.CreateApplicationBuilder` (not `CreateDefaultBuilder`) — a CLI has no hosted services and should not pay for the web-style pipeline. Do **not** call `host.Run()`; the command invocation is the app's lifetime.

## Configuration precedence

Later sources win. The canonical order for a CLI tool:

1. Global user config — `%APPDATA%\<tool>\config.json` / `~/.config/<tool>/config.json`
2. Repo/project config — `<tool>.json`
3. Local override — `.<tool>.json` (gitignored)
4. Environment variables with a tool prefix — `TOOL_`
5. Command-line options (handled by System.CommandLine, on top of all of it)

Every JSON source is `optional: true, reloadOnChange: true`. The tool must run correctly with zero config files present.

## Config POCOs

One class per section in `Configuration/`, every property with a sensible default, XML-doc'd:

```csharp
public class WorktreeConfig
{
    /// <summary>Path pattern for worktrees.</summary>
    public string DirectoryPattern { get; set; } = "../{repo_name}-worktrees/{branch}";

    /// <summary>Auto-fetch on operations.</summary>
    public bool AutoFetch { get; set; } = true;

    /// <summary>Branch prefix with interpolation.</summary>
    public string? BranchPrefix { get; set; }
}
```

Bind with `.Configure<T>(configuration.GetSection("worktree"))` and consume via `IOptionsMonitor<T>.CurrentValue` — never `IOptions<T>`, which would freeze the value and defeat `reloadOnChange`. Read `CurrentValue` once at the top of an action into a local so a mid-action reload cannot produce inconsistent reads.

Config keys are `snake_case` in JSON (`directory_pattern`); the binder matches them to PascalCase properties.

## DI module

All registration lives in one `internal static class Module` with a single chained expression, grouped by kind:

```csharp
internal static IServiceCollection AddServices(this IServiceCollection services, IConfiguration configuration) => services
  // Configuration sections
  .Configure<TerminalConfig>(configuration.GetSection("terminal"))
  .Configure<WorktreeConfig>(configuration.GetSection("worktree"))
  // Services
  .AddSingleton<StateService>()
  .AddSingleton<GitService>()
  .AddSingleton<TerminalService>()
  // Commands and providers
  .AddCommands()
  .AddTerminalProviders();

internal static IServiceCollection AddCommands(this IServiceCollection services) => services
  .AddSingleton<Command, ListCommand>()
  .AddSingleton<Command, SwitchCommand>();
```

Everything is `AddSingleton` — a CLI process handles one invocation, so scoped/transient buy nothing. Commands register **against the `Command` base type** so `IEnumerable<Command>` resolves the full set; register concrete services by concrete type (no interface unless there are genuinely multiple implementations).

## Assembly scanning with Scrutor

Use explicit registration for commands (the list is short and worth reading), and Scrutor only where implementations are numerous and interchangeable — e.g. filtering providers by platform at startup so unusable ones never enter the container:

```csharp
services.Scan(scan => scan
    .FromAssemblyOf<ITerminalProvider>()
    .AddClasses(classes => classes
        .AssignableTo<ITerminalProvider>()
        .Where(type => SupportsCurrentPlatform(type, currentPlatform)))
    .AsImplementedInterfaces()
    .WithSingletonLifetime());
```

Note: assembly scanning is reflection-based and is incompatible with full AOT — it is fine under `PublishTrimmed` only because the types are referenced by the `nameof` switch that maps types to platforms. If you switch to `PublishAot`, replace scanning with explicit registration.

## Logging

Serilog, configured in a `Logging/LoggingExtensions.cs` extension that inspects raw `args` before parsing (the logger must exist before the command tree does):

```csharp
var isDebug = args.Contains("--debug")
    || (Environment.GetEnvironmentVariable("HYPR_DEBUG")?.Equals("true", StringComparison.OrdinalIgnoreCase) ?? false);

Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Is(isDebug ? LogEventLevel.Debug : LogEventLevel.Information)
    .WriteTo.File(PathProvider.GetLogFilePath(),
        outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff} [{Level:u3}] {SourceContext}: {Message:lj}{NewLine}{Exception}",
        rollingInterval: RollingInterval.Day,
        retainedFileCountLimit: 7)
    .WriteTo.Console(restrictedToMinimumLevel: isDebug ? LogEventLevel.Debug : LogEventLevel.Warning)
    .CreateLogger();

services.AddLogging(x => x.ClearProviders().AddSerilog());
```

Key decisions:
- **File sink is verbose, console sink is nearly silent** (`Warning` and above unless `--debug`). Normal CLI output is Spectre.Console, not log lines.
- Rolling daily with `retainedFileCountLimit` so the tool never grows unbounded on a user's disk.
- `ClearProviders()` first — otherwise the host's default console provider double-writes.
- Declare the flag as a `DebugOption` on the `RootCommand` too, so `--help` documents it and parsing does not reject it.

Use structured message templates in services: `_logger.LogInformation("Opening worktree at {Path} with mode {Mode}", path, mode);`

## Platform paths

Never hardcode `~/.config` or `%APPDATA%`. Centralize in a `PathProvider` static class:

```csharp
public static string GetGlobalConfigPath()
{
  var appDataDir = Environment.GetFolderPath(
    OperatingSystem.IsWindows()
      ? Environment.SpecialFolder.ApplicationData
      : Environment.SpecialFolder.UserProfile);

  var configDir = OperatingSystem.IsWindows()
    ? Path.Combine(appDataDir, "hypr")
    : Path.Combine(appDataDir, ".config", "hypr");

  return Path.Combine(configDir, "config.json");
}
```

Logs go to `LocalApplicationData\<tool>\logs` on Windows and `~/.local/share/<tool>/logs` elsewhere; `Directory.CreateDirectory` the log dir before returning the path, since the sink will not create it.

`OperatingSystem.IsWindows()` is the analyzer-aware check for platform-gated APIs; a `PlatformUtils` wrapper over `RuntimeInformation.IsOSPlatform` is fine for plain branching.
