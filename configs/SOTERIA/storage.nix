# This file contains the configuration of disks and storage
{ config, ... }:

with config.lib.custom;

{
  # TODO externalise
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.consoleMode = "auto";
  boot.loader.efi.canTouchEfiVariables = true;

  custom.luks.autoDevices = 3;

  custom.fs.enable = true;
  custom.fs.btrfs.enable = true;
  custom.fs.btrfs.newLayout = true;
}
