#!/bin/zsh

set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_FILE="$HOME/.tmux/plugins/tmux-powerkit/src/renderer/entities/windows.sh"

if [[ ! -f "$TARGET_FILE" ]]; then
    print "tmux-powerkit not installed yet; skipping patch: $TARGET_FILE"
    exit 0
fi

python3 - "$TARGET_FILE" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text()

if "@powerkit_active_window_fg" in text:
    print(f"PowerKit patch already applied: {path}")
    raise SystemExit(0)

original_decl = "local base_color index_bg index_fg content_bg content_fg style"
patched_decl = "local base_color index_bg index_fg content_bg content_fg style active_fg"

if original_decl not in text:
    print("Could not find window color declaration line; patch not applied.", file=sys.stderr)
    raise SystemExit(1)

text = text.replace(original_decl, patched_decl, 1)

pattern = re.compile(
    r'(if \[\[ "\$state" == "active" \]\]; then\n'
    r'\s*base_color="window-active-base"\n)'
    r'\s*index_fg=\$\(resolve_color "\$\{base_color\}-lightest"\)\n'
    r'\s*content_fg=\$\(resolve_color "\$\{base_color\}-lightest"\)\n'
    r'(\s*else\n)'
)

replacement = (
    r'\1'
    r'        active_fg=$(get_tmux_option "@powerkit_active_window_fg" "")\n'
    r'        if [[ -n "$active_fg" ]]; then\n'
    r'            index_fg=$(resolve_color "$active_fg")\n'
    r'            content_fg=$(resolve_color "$active_fg")\n'
    r'        else\n'
    r'            index_fg=$(resolve_color "${base_color}-lightest")\n'
    r'            content_fg=$(resolve_color "${base_color}-lightest")\n'
    r'        fi\n'
    r'\2'
)

text, substitutions = pattern.subn(replacement, text, count=1)

if substitutions != 1:
    print("Could not find active window foreground block; patch not applied.", file=sys.stderr)
    raise SystemExit(1)

path.write_text(text)
print(f"Patched PowerKit window foreground logic: {path}")
PY

if command -v tmux >/dev/null 2>&1 && tmux ls >/dev/null 2>&1; then
    tmux source-file "$SCRIPT_DIR/tmux.conf" >/dev/null 2>&1 || true
    tmux list-clients -F "#{client_tty}" 2>/dev/null | while read -r tty; do
        tmux refresh-client -S -t "$tty" >/dev/null 2>&1 || true
    done
    print "Reloaded tmux config after PowerKit patch."
fi

exit 0
