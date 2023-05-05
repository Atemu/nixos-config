# This file contains the configuration of disks and storage
{ config, ... }:

{
  boot.loader.grub.devices = [ "nodev" ];
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.efiSupport = true;

  custom.luks.autoDevices = 1;

  custom.fs.enable = true;
  custom.fs.btrfs.enable = true;

  # TODO put in custom.btrfs
  # Also, is this still necessary?
  boot.initrd.availableKernelModules = [
    "xxhash_generic" # needed to boot btrfs with xxhash64
  ];

  custom.zramSwap.enable = true;
}
