# This file contains the configuration of disks and storage
{ config, ... }:
{
  boot.loader.grub.devices = [ "nodev" ];
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.efiSupport = true;

  boot.initrd.luks.devices = {
    EXTERNAL-crypt = {
      device = "/dev/disk/by-uuid/34b1261a-ab90-495c-b872-f2f0fd7df14b";
      allowDiscards = true;
    };
  };

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportAll = false;
  boot.zfs.forceImportRoot = false;
  boot.zfs.devNodes = "/dev/mapper/";

  fileSystems."/" = {
    device = "Rpool/R/root";
    fsType = "zfs";
  };
  fileSystems."/nix" = {
    device = "Rpool/R/nix";
    fsType = "zfs";
  };
  fileSystems."/home/" = {
    device = "Rpool/R/home";
    fsType = "zfs";
  };
  fileSystems."/var/" = {
    device = "Rpool/R/var";
    fsType = "zfs";
  };
  fileSystems."/var/tmp" = {
    device = "Rpool/R/tmp";
    fsType = "zfs";
  };
  fileSystems."/tmp/" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "size=50%" "nosuid" "nodev" "nodev" "mode=1777" ]; # systemd default security options
  };
  fileSystems."/boot/" = {
    device = "/dev/disk/by-uuid/69FE-BCF4";
    fsType = "vfat";
    options = [ "umask=077" ];
  };
  fileSystems."/var/lib/docker/" = {
    device = "Rpool/R/docker";
    fsType = "zfs";
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

  services.zfs.trim.enable = true;
  services.zfs.trim.interval = "weekly"; #default

  services.zfs.autoSnapshot.enable = true;

  virtualisation.docker.storageDriver = "zfs";
}
