alias zshrc='vim $HOME/.zshrc'
source $DOTFILES/zsh/aliases.zsh

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  echo "Creating alias for pbcopy and pbpaste"
  alias pbcopy='xclip -selection clipboard'
  alias pbpaste='xclip -selection clipboard -o'
fi
