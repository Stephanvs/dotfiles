export PATH="$PATH:$HOME/.local/bin"
eval "$(oh-my-posh init zsh --config $DOTFILES/powershell/oh-my-posh-theme.json)"

alias zshrc='vim $HOME/.zshrc'
source $DOTFILES/zsh/aliases.zsh

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  alias pbcopy=wl-copy
  alias pbpaste=wl-paste
fi
