Write-Host "Installing fonts" -Verbose

$fonts = (New-Object -ComObject Shell.Application).Namespace(0x14)

foreach ($file in (Get-ChildItem -Path . -Filter *.ttf -Recurse))
{
    $fileName = $file.Name
    if (-Not (Test-Path "C:\Windows\fonts\$fileName" )) {
        Write-Host $fileName -Verbose
        dir $file |  %{ $fonts.CopyHere($_.fullname) }
    }
}

Copy-Item -Filter *.ttf -Destination C:\Windows\Fonts\
