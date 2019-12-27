# This file contains the configuration of disks and storage
{ config, ... }:
{
  boot.loader.grub.devices = [ "nodev" ];
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.efiSupport = true;

  boot.initrd.luks.devices = {
    TRION100-crypt = {
      device = "/dev/disk/by-uuid/28b07833-04a0-4623-8cab-f79e19304720";
      allowDiscards = true;
    };
  };

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportAll = false;
  boot.zfs.forceImportRoot = false;

  fileSystems."/" = {
    device = "Ppool/P/root";
    fsType = "zfs";
  };
  fileSystems."/home/" = {
    device = "Ppool/P/home";
    fsType = "zfs";
  };
  fileSystems."/var/" = {
    device = "Ppool/P/var";
    fsType = "zfs";
  };
  fileSystems."/var/tmp" = {
    device = "Ppool/P/var/tmp";
    fsType = "zfs";
  };
  fileSystems."/tmp/" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "size=50%" "nosuid" "nodev" "nodev" "mode=1777" ]; # systemd default security options
  };
  fileSystems."/boot/" = {
    device = "/dev/disk/by-uuid/1EDB-F8F4";
    fsType = "vfat";
    options = [ "umask=077" ];
  };
  fileSystems."/mnt/Games" = {
    device = "Ppool/P/Games";
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

  services.fstrim.enable = true;
  services.fstrim.interval = "weekly"; # default
}
