{ pkgs, ... }:
{
  imports = [
    ../zsh/home.nix
    ../git/home.nix
    ../ghostty/home.nix
    ../hypr/home.nix
    ../tmux/home.nix
    ../nvim/home.nix
  ];
  home = {
    username = "stephanvs";
    homeDirectory = "/home/stephanvs";
    stateVersion = "26.05";
    packages = with pkgs; [
      bat
      btop
      curl
      eza
      fd
      jq
      ripgrep
      unzip
      wget
      cargo
      rustc
      rust-analyzer
      clang
      cmake
      pkg-config
      nodejs_24
      pnpm
      dotnet-sdk_10
      firefox
      lazygit
    ];
    sessionVariables = {
      EDITOR = "nvim";
      DOTFILES = "/home/stephanvs/dotfiles";
      DOTFILES_HOME = "/home/stephanvs/dotfiles";
      NIXOS_OZONE_WL = "1";
    };
  };
  programs.home-manager.enable = true;
  programs.starship = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ../starship/starship.toml);
  };
  programs.fzf.enable = true;
  programs.zoxide.enable = true;
}
