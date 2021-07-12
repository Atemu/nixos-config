{ ... }:
{
  boot.loader.grub.devices = [ "nodev" ];
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.efiSupport = true;

  boot.initrd.luks.devices = {
    Elements_25A3-crypt = {
      device = "/dev/disk/by-uuid/250918cc-965e-4873-80c9-7361ea622723";
    };
  };

  custom.zfs.enable = true;

  # Deployment
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/165A-C18C";
    fsType = "vfat";
    options = [ "umask=077" ];
  };
  fileSystems."/" = {
    device = "Upool/deployment/root";
    fsType = "zfs";
  };
  fileSystems."/nix" = {
    device = "Upool/deployment/nix";
    fsType = "zfs";
  };
  fileSystems."/var/lib/docker" = {
    device = "Upool/deployment/docker";
    fsType = "zfs";
  };
  # Purposes
  fileSystems."/srv/bz/wine" = {
    device = "Upool/purpose/bz/wine";
    fsType = "zfs";
  };
  fileSystems."/srv/bz/bzvol" = {
    device = "Upool/purpose/bz/bzvol";
    fsType = "zfs";
  };
  fileSystems."/srv/bz/bzthread" = {
    device = "tmpfs";
    fsType = "tmpfs";
  };

  custom.zramSwap.enable = true;
}
