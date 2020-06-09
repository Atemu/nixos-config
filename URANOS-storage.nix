{ ... }:
{
  boot.initrd.luks.devices = {
    Elements_25A3-crypt = {
      device = "/dev/disk/by-uuid/250918cc-965e-4873-80c9-7361ea622723";
    };
  };

  boot.supportedFilesystems = [ "zfs" ];

  # Deployment
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/D266-9E89";
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
}
