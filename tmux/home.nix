{
  config,
  lib,
  pkgs,
  tmuxSources,
  ...
}:
let
  powerkit = (pkgs.callPackage "${tmuxSources.powerkit}/default.nix" { }).overrideAttrs (old: {
    version = "unstable-${tmuxSources.powerkit.shortRev}";
    postInstall = (old.postInstall or "") + ''
      install -m755 ${./plugins/openai_usage.sh} "$target/src/plugins/openai_usage.sh"
      install -m755 ${./plugins/claude_usage.sh} "$target/src/plugins/claude_usage.sh"
      patchShebangs "$target"
    '';
  });
  navigate = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-navigate";
    version = "unstable-${tmuxSources.navigate.shortRev}";
    src = tmuxSources.navigate;
    rtpFilePath = "tmux-navigate.tmux";
  };
in
{
  home.packages = with pkgs; [
    sesh
    gum
    yazi
    opencode
    claude-code
    gemini-cli
    codex
    bc
    lm_sensors
    lsof
    iw
    acpi
    pulseaudio
    bluez
    xdg-utils
  ];
  programs.tmux = {
    enable = true;
    terminal = "tmux-256color";
    keyMode = "vi";
    mouse = true;
    baseIndex = 1;
    escapeTime = 0;
    historyLimit = 50000;
    shell = "${pkgs.zsh}/bin/zsh";
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      navigate
      open
      resurrect
      fzf-tmux-url
      tmux-which-key
      powerkit
      continuum
    ];
  };
  # Apply preferences after Home Manager defaults and before plugin initialization.
  xdg.configFile."tmux/tmux.conf".text = lib.mkOrder 600 (builtins.readFile ./common.conf);
  home.file.".tmux.conf".source = config.xdg.configFile."tmux/tmux.conf".source;
}
