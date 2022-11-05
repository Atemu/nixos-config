# This file contains the configuration of disks and storage
{ config, ... }:

with config.lib.custom;

{
  boot.loader.grub.devices = [ "nodev" ];
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.useOSProber = true;

  # FIXME HEHPAISTOS numeration begins at 1
  custom.luks.devices = [ 1 2 ];

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
