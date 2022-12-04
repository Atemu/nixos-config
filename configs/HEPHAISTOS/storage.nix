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

  custom.fs.btrfs.stateVolumes = [ "Games" ];

  systemd.tmpfiles.rules = [
    "L+ /var/opt/games - - - - /Volumes/Games"
  ];

  custom.btrfs.fileSystems = {
    # TODO refactor fs.nix such that custom.btrfs can be configured for multiple volumes
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
