# This file contains the configuration of disks and storage
{ config, ... }:

with config.lib.custom;

{
  custom.fs.enable = true;
  custom.fs.boot = mkLabel "SOTERIA";
  custom.fs.btrfs.enable = true;
  custom.fs.btrfs.device = mkLabel "SOTERIA-root";

  boot.loader.grub.devices = [ "nodev" ];
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.efiSupport = true;

  boot.initrd.luks.devices = {
    SOTERIA-crypt01 = {
      device = mkLabel "SOTERIA-crypt01";
      allowDiscards = true;
    };
    SOTERIA-crypt02 = {
      device = mkLabel "SOTERIA-crypt02";
      allowDiscards = true;
    };
    SOTERIA-crypt03 = {
      device = mkLabel "SOTERIA-crypt03";
      allowDiscards = true;
    };
  };
}
