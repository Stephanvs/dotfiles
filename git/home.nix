{ pkgs, ... }:
{
  home.packages = [ pkgs.delta ];
  programs.git = {
    enable = true;
    lfs.enable = true;
    includes = [ { path = "~/.gitconfig.local"; } ];
    settings = {
      user = {
        name = "Stephan van Stekelenburg";
        email = "stephan@hayman.io";
      };
      init.defaultBranch = "main";
      core = {
        editor = "nvim";
        autocrlf = "input";
        pager = "delta";
        excludesFile = "~/.config/git/ignore";
      };
      interactive.diffFilter = "delta --color-only";
      delta = {
        navigate = true;
        side-by-side = true;
      };
      pull.rebase = true;
      push.default = "simple";
      merge.conflictStyle = "zdiff3";
      branch.sort = "-committerdate";
      alias.lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%C(bold blue)<%an>%Creset' --abbrev-commit";
    };
  };
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };
  xdg.configFile."git/ignore".source = ./gitignore;
}
