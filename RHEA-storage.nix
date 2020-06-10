# This file contains the configuration of disks and storage
{ config, ... }:
{
  boot.loader.grub.devices = [ "nodev" ];
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.efiSupport = true;

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportAll = false;
  boot.zfs.forceImportRoot = false;
  boot.zfs.devNodes = "/dev/disk/by-id/"; # default

  fileSystems."/" = {
    device = "Rpool/deployment/root";
    fsType = "zfs";
  };
  fileSystems."/nix" = {
    device = "Rpool/deployment/nix";
    fsType = "zfs";
  };
  fileSystems."/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "size=50%" "nosuid" "nodev" "nodev" "mode=1777" ]; # systemd default security options
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/165A-C18C";
    fsType = "vfat";
    options = [ "umask=077" ];
  };

  swapDevices = [ ];

  zramSwap = {
    enable = true;
    algorithm = "lz4";
    memoryPercent = 25;
    numDevices = 1; # default
    priority = 5; # default
    swapDevices = 1; # why do I need this?
  };
}
