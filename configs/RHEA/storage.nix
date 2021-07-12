# This file contains the configuration of disks and storage
{ config, ... }:
{
  boot.loader.grub.devices = [ "nodev" ];
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.efiSupport = true;

  custom.zfs.enable = true;
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

  custom.zramSwap.enable = true;
}
