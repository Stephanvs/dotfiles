eval "$(oh-my-posh init zsh --config $DOTFILES/powershell/oh-my-posh-theme.json)"

alias zshrc='vim $HOME/.zshrc'
source $DOTFILES/zsh/aliases.zsh

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  alias pbcopy='xclip -selection clipboard'
  alias pbpaste='xclip -selection clipboard -o'
fi
