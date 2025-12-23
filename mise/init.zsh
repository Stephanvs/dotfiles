if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
    alias x="mise x --"
fi
