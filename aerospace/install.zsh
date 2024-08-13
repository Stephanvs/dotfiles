AEROSPACE_HOME=$HOME/.config/aerospace

if [ ! -d $AEROSPACE_HOME ]
then
  mkdir -p $AEROSPACE_HOME
fi

# create new symbolic link
ln -nfs $DOTFILES/aerospace/aerospace.toml $AEROSPACE_HOME/aerospace.toml
