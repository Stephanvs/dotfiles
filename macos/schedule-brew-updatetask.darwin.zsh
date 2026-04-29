#!/bin/zsh
set -e
set -u
set -o pipefail

script_dir="${0:A:h}"
export DOTFILES="${DOTFILES:-${script_dir:h}}"
export DOTFILES_HOME="${DOTFILES_HOME:-$DOTFILES}"

source "$DOTFILES/lib/install.zsh"

label="com.stephanvs.dotfiles.brew-update"
launch_agents_dir="$HOME/Library/LaunchAgents"
log_dir="$HOME/Library/Logs/dotfiles"
plist_path="$launch_agents_dir/$label.plist"
updater="$DOTFILES/macos/brew-update-all.zsh"

if [[ "$(uname -s)" != "Darwin" ]]; then
  fail "brew update LaunchAgent can only be installed on macOS"
fi

ensure_dir "$launch_agents_dir"
ensure_dir "$log_dir"

cat > "$plist_path" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$label</string>

  <key>ProgramArguments</key>
  <array>
    <string>$updater</string>
  </array>

  <key>StartCalendarInterval</key>
  <dict>
    <key>Minute</key>
    <integer>0</integer>
  </dict>

  <key>StandardOutPath</key>
  <string>$log_dir/brew-update.log</string>

  <key>StandardErrorPath</key>
  <string>$log_dir/brew-update.err.log</string>
</dict>
</plist>
EOF

chmod 644 "$plist_path"

launchctl bootout "gui/$UID" "$plist_path" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$UID" "$plist_path"
launchctl enable "gui/$UID/$label"

success "Registered hourly Homebrew update LaunchAgent: $label"
