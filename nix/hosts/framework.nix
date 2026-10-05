{ pkgs, ... }:
{
  networking.hostName = "framework";
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  hardware.bluetooth.enable = true;
  services.fwupd.enable = true;
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  users.users.stephanvs.extraGroups = [
    "libvirtd"
    "kvm"
  ];
}
