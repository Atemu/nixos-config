# This file contains the configuration of disks and storage
{ config, ... }:

with config.lib.custom;

{
  custom.fs.enable = true;
  custom.fs.btrfs.enable = true;

  boot.loader.grub.devices = [ "nodev" ];
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.efiSupport = true;

  custom.luks.autoDevices = 3;
}
