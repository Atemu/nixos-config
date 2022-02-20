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
    # TODO abstract these declarations into a function
    HEPHAISTOS-crypt01 = {
      device = mkLabel "HEPHAISTOS-crypt01";
      allowDiscards = true;
    };
    HEPHAISTOS-crypt02 = {
      device = mkLabel "HEPHAISTOS-crypt02";
      allowDiscards = true;
    };
  };

  custom.fs.enable = true;
  custom.fs.boot = mkLabel "HEPHAISTOS";
  custom.fs.btrfs.enable = true;
  custom.fs.btrfs.device = mkLabel "HEPHAISTOS-root";

  custom.btrfs.fileSystems = {
    "/var/opt/games" = {
      subvol = "games";
    };
  };

  custom.zramSwap.enable = true;
}
