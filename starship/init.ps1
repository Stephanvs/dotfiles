# Set Starship home directory
$ENV:STARSHIP_CONFIG = "$HOME\dotfiles\starship"
# Initialize starship in powershell configuration
Invoke-Expression (&starship init powershell)