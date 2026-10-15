# REA on Windows

[REA](https://github.com/morluto/rea) connects Codex to local binary-analysis tools.
This module installs REA 6.5.0, registers its MCP server and bundled skill with
Codex, and saves Ghidra and Java settings in the Windows user environment.
REA backs up the existing Codex configuration before updating it.

Requires Node.js 22.19+, 24.11+, or 26+, Ghidra 12.1.x, and a full 64-bit JDK 21+.
The installer reuses Scoop's Ghidra installation and discovers Oracle JDKs under
`C:\Program Files\Java`. Other installations can be supplied explicitly:

```powershell
.\rea\install.ps1 -GhidraPath C:\tools\ghidra_12.1.4_PUBLIC -JavaHome C:\tools\jdk-21
```

Restart Codex after setup. Open a new terminal for the saved environment settings.
Then ask Codex to use REA to inspect a binary at its absolute path, or run:

```powershell
rea doctor --client codex --provider ghidra --skill --json
rea inspect 'C:\binaries\example.exe' --provider ghidra --format json
```

[Windows Ghidra support is experimental](https://github.com/morluto/rea/blob/main/docs/windows-ghidra-p0.md).
It supports read-only native x86/x64 PE EXE and DLL analysis. Targets and temporary
files must be on local NTFS volumes, without symlinks or junctions in target paths.
Managed .NET inspection uses REA's separate static provider.

After upgrading Ghidra or Java, rerun this module to refresh the saved paths.
To upgrade REA, pass `-Version` with the desired release and restart Codex.
