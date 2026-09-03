# Packaging and Distribution

- [Tool packaging](#tool-packaging)
- [RID-specific self-contained builds](#rid-specific-self-contained-builds)
- [Trimming safety](#trimming-safety)
- [Build commands](#build-commands)

## Tool packaging

A single `src/<tool>.csproj` is both the app and the NuGet tool package:

```xml
<PropertyGroup>
  <OutputType>Exe</OutputType>
  <TargetFramework>net10.0</TargetFramework>
  <Nullable>enable</Nullable>
  <ImplicitUsings>enable</ImplicitUsings>

  <AssemblyName>hypr</AssemblyName>
  <PackageId>hypr</PackageId>
  <Description>Customizable git worktree manager</Description>
  <PackageTags>git;worktree;cli</PackageTags>
  <PackageLicenseExpression>MIT</PackageLicenseExpression>
  <PackageReadmeFile>README.md</PackageReadmeFile>

  <PackAsTool>true</PackAsTool>
  <ToolCommandName>hypr</ToolCommandName>
  <PackageOutputPath>./nupkg</PackageOutputPath>
</PropertyGroup>

<ItemGroup>
  <None Include="../README.md" Pack="true" PackagePath="README.md" />
</ItemGroup>
```

`ToolCommandName` is what users type; keep it identical to `AssemblyName` and `PackageId`. The repo README is packed in explicitly because it lives above the project directory.

Prefer a `.slnx` solution file (terse XML, no GUIDs):

```xml
<Solution>
  <Project Path="src/hypr.csproj" />
  <Project Path="tests/tests.csproj" />
</Solution>
```

## RID-specific self-contained builds

Ship per-platform single-file binaries plus a portable `any` fallback so `dotnet tool install` works with or without a matching runtime:

```xml
<RuntimeIdentifiers>win-x64;linux-x64;linux-arm64;osx-x64;osx-arm64;any</RuntimeIdentifiers>
<ToolPackageRuntimeIdentifiers>win-x64;linux-x64;linux-arm64;osx-x64;osx-arm64;any</ToolPackageRuntimeIdentifiers>
```

Single-file settings apply **only** to RID-specific publishes, guarded by a condition — applying them unconditionally breaks the `any` package and local `dotnet run`:

```xml
<PropertyGroup Condition="'$(RuntimeIdentifier)' != '' and '$(RuntimeIdentifier)' != 'any'">
  <PublishSingleFile>true</PublishSingleFile>
  <SelfContained>true</SelfContained>
  <PublishTrimmed>true</PublishTrimmed>
  <TrimMode>link</TrimMode>
  <EnableCompressionInSingleFile>true</EnableCompressionInSingleFile>
  <!-- Embed native libraries (e.g. LibGit2Sharp) and auto-extract at runtime -->
  <IncludeNativeLibrariesForSelfExtract>true</IncludeNativeLibrariesForSelfExtract>
</PropertyGroup>
```

`IncludeNativeLibrariesForSelfExtract` is mandatory whenever a dependency carries native assets (LibGit2Sharp, SQLite, Skia); without it the single-file binary throws `DllNotFoundException` at runtime, not at build.

## Trimming safety

`PublishTrimmed` removes reflection-only code paths. Two things to get right:

**JSON** — use a source-generated `JsonSerializerContext` and pass it to every serialize/deserialize call:

```csharp
[JsonSourceGenerationOptions(WriteIndented = true, PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase)]
[JsonSerializable(typeof(AppState))]
[JsonSerializable(typeof(GitHubRelease))]
internal partial class AppJsonSerializerContext : JsonSerializerContext { }
```

Every type that crosses the JSON boundary needs its own `[JsonSerializable]` attribute — a missing one fails only at runtime, in the trimmed build.

**Reflection** — `Configure<T>` binding and Scrutor scanning both use reflection. They survive trimming when the types are statically referenced elsewhere (config POCOs by `Configure<T>`, providers by a `nameof(...)` switch), but they are **not** AOT-safe. Verify a trimmed publish actually runs before releasing; do not assume a clean build means a working binary.

## Build commands

Pipe output to a file and grep, so a noisy build cannot flood context:

```bash
dotnet build > /tmp/dotnet-build.txt 2>&1
```

```bash
grep -E "error|warning" /tmp/dotnet-build.txt
```

Verify a real release artifact:

```bash
dotnet publish src/hypr.csproj -c Release -r win-x64 > /tmp/dotnet-publish.txt 2>&1
```

Add packages and references through the CLI only:

```bash
dotnet add src/hypr.csproj package Spectre.Console
```

```bash
dotnet add tests/tests.csproj reference src/hypr.csproj
```
