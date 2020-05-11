alias zshrc='vim $HOME/.zshrc'

if [ "$(uname 2> /dev/null)" == "Linux" ]; then
  alias pbcopy='xclip -selection clipboard'
  alias pbpaste='xclip -selection clipboard -o'
fi