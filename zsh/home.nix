{ ... }:
{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    defaultKeymap = "viins";
    history = {
      size = 50000;
      save = 50000;
    };
    shellAliases = {
      vi = "nvim";
      vim = "nvim";
      l = "eza --long --icons --all --group-directories-first --no-filesize";
      ll = "ls -l";
      la = "ls -lA";
      md = "mkdir -p";
      cwd = "pwd | wl-copy";
    };
    initContent = ''
      if [[ -z "$SSH_CLIENT" && -z "$SSH_TTY" ]]; then
        export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
      fi
    '';
  };
}
