# dotfiles

![](img/wsl.png)

# Setting up a new Linux machine

## install zsh
    $ sudo apt install zsh
    $ chsh -s $(which zsh)

## install oh-my-zsh
    $ sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

## install space vim
    $ curl -sLf https://spacevim.org/install.sh | bash

## install i3-gaps
    $ sudo add-apt-repository ppa:kgilmer/speed-ricer
    $ sudo apt-get update
    $ sudo apt install i3-gaps

## install polybar
    $ sudo apt install polybar