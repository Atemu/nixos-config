# This file contains the configuration of disks and storage
{ config, ... }:

with config.lib.custom;

{
  custom.bootloader = "systemd-boot";

  custom.luks.autoDevices = 3;

  custom.fs.enable = true;
  custom.fs.btrfs.enable = true;
  custom.fs.btrfs.newLayout = true;

  custom.btrfs.fileSystems = {
    # TODO refactor fs.nix such that custom.btrfs can be configured for multiple volumes
    "/Volumes/Data" = {
      subvol = "/";
      device = mkLabel "${config.custom.hostName}-data";
    };
  };
}
