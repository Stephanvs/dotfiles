$AppPackages = @(
    "Microsoft.BingNews"
    "Microsoft.BingWeather"
    "Microsoft.GetHelp"
    "Microsoft.Getstarted"
    "Microsoft.People"
    "Microsoft.Microsoft3DViewer"
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.MicrosoftSolitaireCollection"
    "Clipchamp.Clipchamp"
    "Microsoft.YourPhone"
    "Microsoft.PowerAutomateDesktop"
    # Add more package names as needed
)

# Remove packages for all users
foreach ($App in $AppPackages) {
    Write-Host "Removing $App for all users..."

    Get-AppxPackage -Name $App -AllUsers `
        | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
}

# Restart explorer process to apply changes
Stop-Process -Name explorer -Force
# Start-Process explorer.exe
