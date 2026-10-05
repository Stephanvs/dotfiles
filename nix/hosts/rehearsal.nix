{ lib, ... }:
{
  networking.hostName = "nixos-rehearsal";
  virtualisation = {
    memorySize = 8192;
    cores = 4;
    diskSize = 49152;
    useBootLoader = true;
    useEFIBoot = true;
    forwardPorts = [
      {
        from = "host";
        host.address = "127.0.0.1";
        host.port = 2222;
        guest.port = 22;
      }
    ];
  };
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  users.users.stephanvs.initialPassword = "rehearsal";
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };
  services.greetd.settings.initial_session = {
    command = "uwsm start hyprland.desktop";
    user = "stephanvs";
  };
  environment.sessionVariables = {
    LIBGL_ALWAYS_SOFTWARE = "1";
    AQ_NO_MODIFIERS = "1";
  };
  home-manager.users.stephanvs.wayland.windowManager.hyprland.settings.monitor = lib.mkForce [
    ",1920x1080@60,auto,1"
  ];
}
