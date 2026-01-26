# remove existing config directory/symlink
rm -rf $HOME/.config/opencode

# create the directory
mkdir -p $HOME/.config/opencode

# create new symbolic links
ln -nfs $DOTFILES/opencode/opencode.json $HOME/.config/opencode/opencode.json
ln -nfs $DOTFILES/opencode/prompts $HOME/.config/opencode/prompts
ln -nfs $DOTFILES/opencode/skills $HOME/.config/opencode/skills
ln -nfs $DOTFILES/opencode/rules $HOME/.config/opencode/rules
ln -nfs $DOTFILES/opencode/themes $HOME/.config/opencode/themes
ln -nfs $DOTFILES/opencode/AGENTS.md $HOME/.config/opencode/AGENTS.md
ln -nfs $DOTFILES/opencode/command $HOME/.config/opencode/command
