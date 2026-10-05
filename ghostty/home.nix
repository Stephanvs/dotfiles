{ ... }:
{
  programs.ghostty.enable = true;
  xdg.configFile."ghostty/config".source = ./config;
}
