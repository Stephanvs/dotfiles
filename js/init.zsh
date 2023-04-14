source $DOTFILES/js/aliases.zsh

# pnpm
export PNPM_HOME="/Users/stephanvs/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
