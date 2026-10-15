[CmdletBinding()]
param(
    [string]$GhidraPath = "$HOME\scoop\apps\ghidra\current",
    [string]$JavaHome = $env:JAVA_HOME,
    [string]$Version = '6.5.0'
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    throw 'Install a supported Node.js LTS release with npm first.'
}

if (-not (Test-Path "$GhidraPath\support\analyzeHeadless.bat")) {
    throw 'Install Ghidra with scoop install extras/ghidra, or supply -GhidraPath.'
}
# Use the version directory rather than Scoop's junction for Windows admission.
$ghidraItem = Get-Item -LiteralPath $GhidraPath
if ($ghidraItem.Target) { $GhidraPath = @($ghidraItem.Target)[0] }

if (-not $JavaHome) {
    $JavaHome = Get-ChildItem 'C:\Program Files\Java' -Directory -Filter 'jdk-*' |
        Where-Object { Test-Path (Join-Path $_.FullName 'bin\javac.exe') } |
        Sort-Object Name -Descending |
        Select-Object -First 1 -ExpandProperty FullName
}
if (-not $JavaHome -or -not (Test-Path "$JavaHome\bin\javac.exe")) {
    throw 'A full 64-bit JDK 21 or newer is required. Supply its directory with -JavaHome.'
}

& npm install --global "rea-agents@$Version"
if ($LASTEXITCODE -ne 0) { throw 'REA installation failed.' }

$env:GHIDRA_INSTALL_DIR = $GhidraPath
$env:JAVA_HOME = $JavaHome
$env:REA_ANALYSIS_PROVIDER = 'ghidra'

& rea doctor --provider ghidra --json
if ($LASTEXITCODE -ne 0) { throw 'Ghidra readiness check failed; environment settings were not persisted.' }

& rea setup --client codex --yes --json
if ($LASTEXITCODE -ne 0) { throw 'REA Codex setup failed.' }

foreach ($name in @('GHIDRA_INSTALL_DIR', 'JAVA_HOME', 'REA_ANALYSIS_PROVIDER')) {
    [Environment]::SetEnvironmentVariable($name, (Get-Item "Env:$name").Value, 'User')
}

Write-Host 'REA is configured. Restart Codex and open a new terminal to load the settings.'
