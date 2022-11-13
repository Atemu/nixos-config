# This file contains the configuration of disks and storage
{ config, ... }:

with config.lib.custom;

{
  # TODO externalise
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;

  custom.luks.autoDevices = 4;

  custom.fs.enable = true;
  custom.fs.btrfs.enable = true;
  custom.fs.btrfs.newLayout = true;

  systemd.tmpfiles.rules = [
    "L+ /var/opt/games - - - - /Volumes/Games"
  ];

  custom.btrfs.fileSystems = {
    "/Volumes/Games" = {
      subvol = "Games";
    };

    "/Volumes/Data" = {
      subvol = "";
      device = mkLabel "${config.custom.hostName}-data";
    };
  };

  nix.settings.extra-sandbox-paths = [
    "/Volumes/Data/Ccache/"
  ];

  custom.zramSwap.enable = true;
}
