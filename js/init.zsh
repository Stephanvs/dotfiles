source $DOTFILES/js/aliases.zsh

# nvm
export NVM_DIR=~/.nvm
source $(brew --prefix nvm)/nvm.sh
# end nvm

# pnpm
export PNPM_HOME="/Users/stephanvs/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
