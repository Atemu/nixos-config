# This file contains the configuration of disks and storage
{ config, ... }:

with config.lib.custom;

{
  # TODO externalise
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;

  # FIXME HEHPAISTOS mount all the disks
  custom.luks.devices = [ 0 3 ];

  custom.fs.enable = true;
  custom.fs.newLayout = true;
  custom.fs.btrfs.enable = true;

  systemd.tmpfiles.rules = [
    "L+ /var/opt/games - - - - /Volumes/Games"
  ];

  custom.btrfs.fileSystems = {
    "/Volumes/Games" = {
      subvol = "Games";
    };
  };

  custom.zramSwap.enable = true;
}
