# remove existing config directory/symlink
rm -rf $HOME/.config/opencode

# create new symbolic link
ln -nfs $DOTFILES/opencode/opencode.json $HOME/.config/opencode/opencode.json
ln -nfs $DOTFILES/opencode/prompts $HOME/.config/opencode/prompts
ln -nfs $DOTFILES/opencode/skill $HOME/.config/opencode/skill
ln -nfs $DOTFILES/opencode/rules $HOME/.config/opencode/rules
ln -nfs $DOTFILES/opencode/AGENTS.md $HOME/.config/opencode/AGENTS.md
ln -nfs $DOTFILES/opencode/command $HOME/.config/opencode/command
