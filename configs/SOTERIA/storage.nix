# This file contains the configuration of disks and storage
{ config, ... }:

with config.lib.custom;

{
  custom.bootloader.choice = "systemd-boot";

  custom.luks.autoDevices = 3;

  custom.fs.enable = true;
  custom.fs.btrfs.enable = true;
  custom.fs.btrfs.newLayout = true;

  # The zpool is managed imperatively and the network address is hard-coded for now
  # as this is a temporary setup
  boot.supportedFilesystems = [
    "zfs"
  ];
  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /share/media 192.168.178.0/24(ro)
  '';
  networking.firewall = {
    # It needs one or some of these ports AFAICT
    allowedTCPPorts = [ 111 2049 4000 4001 4002 20048 ];
    allowedUDPPorts = [ 111 2049 4000 4001 4002 20048 ];
  };

  custom.btrfs.fileSystems = {
    # TODO refactor fs.nix such that custom.btrfs can be configured for multiple volumes
    "/Volumes/Data" = {
      subvol = "/";
      device = mkLabel "${config.networking.hostName}-data";
    };
  };
}
