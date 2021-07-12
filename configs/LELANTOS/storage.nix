{
  boot.supportedFilesystems = [ "zfs" ];

  # Deployment-specific
  fileSystems."/" = {
    device = "Lpool/deployment/root";
    fsType = "zfs";
  };
  fileSystems."/nix" = {
    device = "Lpool/deployment/nix";
    fsType = "zfs";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/038E-8BC2";
    fsType = "vfat";
    options = [ "umask=077" ];
  };
  # Purpose-specific
  fileSystems."/home" = {
    device = "Lpool/purpose/home";
    fsType = "zfs";
  };

  custom.zramSwap.enable = true;
  custom.zramSwap.percent = 50;
}
