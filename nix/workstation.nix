{ pkgs, ... }:
{
  system.stateVersion = "26.05";
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;

  time.timeZone = "Europe/Amsterdam";
  i18n.defaultLocale = "en_US.UTF-8";
  networking.networkmanager.enable = true;

  users.users.stephanvs = {
    isNormalUser = true;
    description = "Stephan van Stekelenburg";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;
  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };
  services.greetd = {
    enable = true;
    settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd 'uwsm start hyprland.desktop'";
  };
  security.pam.services.hyprlock = { };
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  services.gnome.gnome-keyring.enable = true;
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "stephanvs" ];
  };
  fonts.packages = [
    (pkgs.runCommand "berkeley-mono-nerd-font" { } ''
      mkdir -p "$out/share/fonts/truetype"
      cp ${../fonts/berkeley-mono-nerd-font}/BerkeleyMonoNerdFont-{Regular,Bold,Italic,BoldItalic}.ttf "$out/share/fonts/truetype/"
    '')
    pkgs.nerd-fonts.jetbrains-mono
  ];
  environment.systemPackages = with pkgs; [
    git
    pciutils
    usbutils
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.stephanvs = import ./home.nix;
  };
}
