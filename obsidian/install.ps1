Import-Module -Name "$PSScriptRoot\..\lib\Symlink.psm1"

$vaultPath = "$env:USERPROFILE\notes"
$repoUrl = "git@github.com:Stephanvs/notes.git"
$sshCommand = "C:/Windows/System32/OpenSSH/ssh.exe"

if (-not (Test-Path -LiteralPath $vaultPath)) {
    & git -c "core.sshCommand=$sshCommand" clone $repoUrl $vaultPath
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to clone notes repo to $vaultPath"
    }
}
elseif (-not (Test-Path -LiteralPath "$vaultPath\.git")) {
    Write-Warning "$vaultPath exists and is not a Git repo; skipping clone"
}

if (Test-Path -LiteralPath "$vaultPath\.git") {
    & git -C $vaultPath config core.sshCommand $sshCommand
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to configure SSH for $vaultPath"
    }
}

New-Symlink -SourcePath "$PSScriptRoot" -TargetPath "$vaultPath\.obsidian" -Label 'Obsidian config link'
