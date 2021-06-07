# This file contains the configuration of disks and storage
{ config, ... }:

with config.lib.custom;

{
  boot.loader.grub.devices = [ "nodev" ];
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.useOSProber = true;

  # TODO refactor into custom.luksPools
  boot.initrd.luks.devices = {
    CT1000MX500-crypt = {
      device = "/dev/disk/by-uuid/37473d86-55d3-4101-a7d7-16474d8a176d";
      allowDiscards = true;
    };
  };

  custom.fs.enable = true;
  custom.fs.boot = mkUuid "21F5-7652"; # TODO change
  custom.fs.btrfs.enable = true;
  custom.fs.btrfs.device = mkUuid "1700c195-e991-4c08-9055-5d0403fb1cc6"; # TODO change

  custom.btrfs.fileSystems = {
    "/var/opt/games" = {
      subvol = "games";
    };
  };

  custom.zramSwap.enable = true;
}
