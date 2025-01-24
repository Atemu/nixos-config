{ pkgs, ... }:

{
  imports = [
    ../../common.nix
    ../../hardware/FW16.nix
  ];

  networking.hostName = "THESEUS";

  custom.desktop.enable = true;
  custom.desktop.hypr.enable = true;

  boot.initrd.systemd.enable = true;

  custom.dnscrypt.enable = true;

  environment.systemPackages = with pkgs; [
    prusa-slicer
  ];

  custom.bootloader.choice = "systemd-boot";

  custom.luks.autoDevices = 1;

  custom.fs.enable = true;
  custom.fs.btrfs.enable = true;
  custom.fs.btrfs.newLayout = true;

  # Device name must be provided by hardware config for now
  custom.swap.devices.primary.enable = true;

  system.stateVersion = "24.11";
}
