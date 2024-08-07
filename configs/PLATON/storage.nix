# This file contains the configuration of disks and storage
{ ... }:

{
  # TODO externalise
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  custom.luks.autoDevices = 1;

  custom.fs.enable = true;
  custom.fs.btrfs.enable = true;
  custom.fs.btrfs.newLayout = true;

  # TODO put in custom.btrfs
  # Also, is this still necessary?
  boot.initrd.availableKernelModules = [
    "xxhash_generic" # needed to boot btrfs with xxhash64
  ];

  custom.zramSwap.enable = true;
}
