# .NET Development Guidelines

## Building Projects

To prevent context window overflow when building:

```bash
# Pipe build output to temp file
dotnet build > /tmp/dotnet-build.txt 2>&1

# Then check for errors/warnings
grep -E "error|warning" /tmp/dotnet-build.txt

# Or get a summary
tail -20 /tmp/dotnet-build.txt
```

For large solutions, build specific projects:
```bash
dotnet build src/MyProject/MyProject.csproj > /tmp/dotnet-build.txt 2>&1
```

## Running Tests

Same approach for tests:
```bash
dotnet test > /tmp/dotnet-test.txt 2>&1
grep -E "Failed|Passed|Error" /tmp/dotnet-test.txt
```

## Project References

ALWAYS use the CLI to add project references:
```bash
dotnet add src/MyProject/MyProject.csproj reference src/OtherProject/OtherProject.csproj
```

NEVER manually edit .csproj files to add `<ProjectReference>` elements.

## NuGet Packages

ALWAYS use the CLI to add packages:
```bash
dotnet add package Newtonsoft.Json
dotnet add package Newtonsoft.Json --version 13.0.1
```

To remove packages:
```bash
dotnet remove package Newtonsoft.Json
```

NEVER manually edit .csproj files to add `<PackageReference>` elements.

## Creating New Projects

Use the CLI for all project creation:
```bash
# List available templates
dotnet new list

# Common templates
dotnet new classlib -n MyLibrary
dotnet new console -n MyApp
dotnet new webapi -n MyApi
dotnet new xunit -n MyProject.Tests

# With specific framework
dotnet new classlib -n MyLibrary -f net8.0
```

## Adding Projects to Solutions

```bash
dotnet sln add src/MyProject/MyProject.csproj
dotnet sln remove src/OldProject/OldProject.csproj
dotnet sln list
```

## Restoring Dependencies

```bash
dotnet restore
```

## Publishing

```bash
dotnet publish -c Release -o ./publish
```

## Common Patterns

### Check if build succeeds without full output
```bash
dotnet build --nologo -v q && echo "Build succeeded" || echo "Build failed"
```

### Get just error count
```bash
dotnet build 2>&1 | grep -c "error CS"
```
