# Ensure config directory exists
if (-not (Test-Path $HOME\.config\opencode)) {
    New-Item -ItemType Directory -Path $HOME\.config\opencode -Force | Out-Null
}

# Create symbolic links
New-Item -ItemType SymbolicLink -Path $HOME\.config\opencode\opencode.json -Target $PSScriptRoot\opencode.json -Force | Out-Null
New-Item -ItemType SymbolicLink -Path $HOME\.config\opencode\prompts -Target $PSScriptRoot\prompts -Force | Out-Null
New-Item -ItemType SymbolicLink -Path $HOME\.config\opencode\skill -Target $PSScriptRoot\skill -Force | Out-Null
New-Item -ItemType SymbolicLink -Path $HOME\.config\opencode\rules -Target $PSScriptRoot\rules -Force | Out-Null
New-Item -ItemType SymbolicLink -Path $HOME\.config\opencode\AGENTS.md -Target $PSScriptRoot\AGENTS.md -Force | Out-Null
New-Item -ItemType SymbolicLink -Path $HOME\.config\opencode\command -Target $PSScriptRoot\command -Force | Out-Null
