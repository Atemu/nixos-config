# This file contains the configuration of disks and storage
{ config, ... }:
{
  boot.loader.grub.devices = [ "nodev" ];
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.efiSupport = true;

  custom.luks.devices = {
    MZNTE128HMGR-crypt = {
      device = "/dev/disk/by-uuid/6f9558c5-593c-4c86-b88f-63cc5b031ff0";
    };
  };

  custom.zfs.enable = true;
  boot.zfs.devNodes = "/dev/mapper/";

  # Instance-specific
  fileSystems."/" = {
    device = "Ppool/instance/root";
    fsType = "zfs";
  };
  fileSystems."/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "size=50%" "nosuid" "nodev" "nodev" "mode=1777" ]; # systemd default security options
  };
  # Deployment-specific
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/3075-C917";
    fsType = "vfat";
    options = [ "umask=077" ];
  };
  fileSystems."/nix" = {
    device = "Ppool/deployment/nix";
    fsType = "zfs";
  };
  fileSystems."/var/lib/docker" = {
    device = "Ppool/deployment/docker";
    fsType = "zfs";
  };
  # Purpose-specific
  fileSystems."/home" = {
    device = "Ppool/purpose/home";
    fsType = "zfs";
  };
  fileSystems."/etc/NetworkManager/system-connections" = {
    device = "Ppool/purpose/nm-connections";
    fsType = "zfs";
  };
  fileSystems."/var/opt/games" = {
    device = "Ppool/purpose/games";
    fsType = "zfs";
  };

  swapDevices = [ ];

  zramSwap = {
    enable = true;
    algorithm = "lz4";
    memoryPercent = 50;
    numDevices = 1; # default
    priority = 5; # default
    swapDevices = 1; # why do I need this?
  };
}
