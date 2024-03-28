[CmdletBinding()]
Param()

function grep {
  $input | out-string -stream | select-string $args
}

function Touch-File
{
    $file = $args[0]
    if($file -eq $null) {
        throw "No filename supplied"
    }

    if(Test-Path $file)
    {
        (Get-ChildItem $file).LastWriteTime = Get-Date
    }
    else
    {
        echo $null > $file
    }
}
New-Alias -Name touch Touch-File

function CopyWorkingDirectory { pwd | Set-Clipboard }
Set-Alias -Name cwd -Value CopyWorkingDirectory -Force -Scope Global
