# This file contains the configuration of disks and storage
{ ... }:
{
  boot.loader.grub.devices = [ "nodev" ];
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.efiSupport = true;

  boot.initrd.luks.devices = {
    CT1000MX500-crypt = {
      device = "/dev/disk/by-uuid/37473d86-55d3-4101-a7d7-16474d8a176d";
      allowDiscards = true;
    };
  };

  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportAll = false;
  boot.zfs.forceImportRoot = false;
  boot.zfs.devNodes = "/dev/mapper/";

  # Instance-specific
  fileSystems."/" = {
    device = "Hpool/instance/root";
    fsType = "zfs";
  };
  fileSystems."/tmp" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "size=50%" "nosuid" "nodev" "nodev" "mode=1777" ]; # systemd default security options
  };
  # Deployment-specific
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/479D-9EFF";
    fsType = "vfat";
    options = [ "umask=077" ];
  };
  fileSystems."/nix" = {
    device = "Hpool/deployment/nix";
    fsType = "zfs";
  };
  fileSystems."/var/lib/docker" = {
    device = "Hpool/deployment/docker";
    fsType = "zfs";
  };
  # Purpose-specific
  fileSystems."/home" = {
    device = "Hpool/purpose/home";
    fsType = "zfs";
  };
  fileSystems."/var/opt/games" = {
    device = "Hpool/purpose/games";
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

  services.zfs.trim.enable = true;
  services.zfs.trim.interval = "weekly"; #default

  services.zfs.autoSnapshot.enable = true;

  virtualisation.docker.storageDriver = "zfs";
}
