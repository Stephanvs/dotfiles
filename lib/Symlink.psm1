function Resolve-LinkTargetPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LinkPath,

        [AllowNull()]
        [Parameter(Mandatory = $true)]
        [object]$Target
    )

    $rawTarget = if ($Target -is [Array]) { $Target[0] } else { $Target }
    if ([string]::IsNullOrWhiteSpace($rawTarget)) {
        return $null
    }

    $candidate = [string]$rawTarget
    if (-not [System.IO.Path]::IsPathRooted($candidate)) {
        $linkDirectory = Split-Path -Path $LinkPath -Parent
        $candidate = Join-Path -Path $linkDirectory -ChildPath $candidate
    }

    return [System.IO.Path]::GetFullPath($candidate)
}

function Resolve-PathWithSymlinks {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $root = [System.IO.Path]::GetPathRoot($fullPath)

    if ([string]::IsNullOrWhiteSpace($root)) {
        return $fullPath
    }

    $segments = $fullPath.Substring($root.Length) -split '[\\/]'
    $resolvedPath = $root

    foreach ($segment in $segments) {
        if ([string]::IsNullOrWhiteSpace($segment)) {
            continue
        }

        $candidatePath = Join-Path -Path $resolvedPath -ChildPath $segment

        if (Test-Path -LiteralPath $candidatePath) {
            $item = Get-Item -LiteralPath $candidatePath -Force -ErrorAction Stop

            if ($null -ne $item.LinkType) {
                $linkTargetPath = Resolve-LinkTargetPath -LinkPath $candidatePath -Target $item.Target
                if (-not [string]::IsNullOrWhiteSpace($linkTargetPath)) {
                    $resolvedPath = $linkTargetPath
                    continue
                }
            }
        }

        $resolvedPath = $candidatePath
    }

    return [System.IO.Path]::GetFullPath($resolvedPath)
}

function New-Symlink {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$TargetPath,

        [string]$Label = "Symlink"
    )

    if (-not (Test-Path -LiteralPath $SourcePath)) {
        throw "Source not found: $SourcePath"
    }

    $normalizedSourcePath = [System.IO.Path]::GetFullPath($SourcePath)
    $resolvedSourcePath = Resolve-PathWithSymlinks -Path $normalizedSourcePath
    $resolvedTargetPath = Resolve-PathWithSymlinks -Path $TargetPath

    if ($resolvedTargetPath -eq $resolvedSourcePath) {
        Write-Host "$Label already resolves to $resolvedSourcePath"
        return
    }

    $targetDirectory = Split-Path -Path $TargetPath -Parent
    New-Item -ItemType Directory -Path $targetDirectory -Force -ErrorAction Stop | Out-Null

    if (Test-Path -LiteralPath $TargetPath) {
        $existingItem = Get-Item -LiteralPath $TargetPath -Force -ErrorAction Stop
        $isLink = $null -ne $existingItem.LinkType

        if ($isLink) {
            $existingTargetPath = Resolve-LinkTargetPath -LinkPath $TargetPath -Target $existingItem.Target

            if ($existingTargetPath -eq $normalizedSourcePath) {
                Write-Host "$Label already points to $normalizedSourcePath"
                return
            }

            Remove-Item -LiteralPath $TargetPath -Force -ErrorAction Stop
        }
        else {
            $backupPath = "$TargetPath.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
            Move-Item -LiteralPath $TargetPath -Destination $backupPath -Force -ErrorAction Stop
            Write-Host "Backed up existing item to $backupPath"
        }
    }

    try {
        New-Item -ItemType SymbolicLink -Path $TargetPath -Target $normalizedSourcePath -Force -ErrorAction Stop | Out-Null
        Write-Host "Linked $TargetPath -> $normalizedSourcePath"
    }
    catch {
        throw "Failed to create symbolic link. Run this script as Administrator or enable Developer Mode. $($_.Exception.Message)"
    }
}

Export-ModuleMember -Function New-Symlink
