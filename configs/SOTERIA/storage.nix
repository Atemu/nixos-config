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

  services.nfs.server.enable = true;
  # These are media shares intended to be consume by a hacky libreelec setup I inherited.
  # /Volumes/Data/Media is a media library I also inherited.
  # /Volumes/Data/Movies is my Movies and shows library.
  # TODO Rework the network they're exposed to better, it breaks with Tailscale currently.
  services.nfs.server.exports = ''
    /Volumes/Data/Media/ 192.168.178.0/24(ro)
    /Volumes/Data/Movies/ 192.168.178.0/24(ro)
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
