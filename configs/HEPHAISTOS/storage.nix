# This file contains the configuration of disks and storage
{ config, ... }:

let
  inherit (config.lib.custom) mkLabel;
in

{
  custom.bootloader.choice = "systemd-boot";

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
      subvol = "/";
      device = mkLabel "${config.networking.hostName}-data";
    };
  };

  nix.settings.extra-sandbox-paths = [
    "/var/cache/ccache=/Volumes/Data/Ccache/?"
  ];

  custom.zramSwap.enable = true;
}
