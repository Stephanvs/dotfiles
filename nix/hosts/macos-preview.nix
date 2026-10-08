{
  config,
  lib,
  pkgs,
  ...
}:
let
  image = import "${pkgs.path}/nixos/lib/make-disk-image.nix" {
    inherit config lib pkgs;
    format = "qcow2";
    partitionTableType = "efi";
    diskSize = config.virtualisation.diskSize;
    copyChannel = false;
    # Install EFI/BOOT/BOOTAA64.EFI without running EFI firmware in the
    # builder. The final VM boots that fallback path with real UEFI firmware.
    touchEFIVars = false;
  };
in
{
  services.pipewire.alsa.support32Bit = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;
  virtualisation.sharedDirectories = lib.mkForce { };

  # Hyprpaper 0.8 uses DMA-BUF allocation, which the software-only QEMU
  # display cannot provide. Swaybg uses shared-memory buffers for this guest.
  home-manager.users.stephanvs = {
    services.hyprpaper.enable = lib.mkForce false;
    systemd.user.services.nixos-preview-wallpaper = {
      Unit = {
        Description = "Wallpaper for the software-rendered Mac preview";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.swaybg}/bin/swaybg -i ${../../wallpapers/a-chosen-soul.jpg} -m fill";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };

  system.build.macosPreview = pkgs.runCommand "nixos-macos-preview" { } ''
    mkdir -p "$out"
    ln -s ${image}/nixos.qcow2 "$out/disk.qcow2"
    ln -s ${config.virtualisation.efi.variables} "$out/efi-vars.fd"
    ln -s ${config.virtualisation.efi.firmware} "$out/efi-code.fd"
    ln -s ${pkgs.novnc}/share/webapps/novnc "$out/novnc"
    ln -s ${config.system.build.toplevel} "$out/system"
  '';
}
