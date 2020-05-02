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
  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/2178-694E";
      fsType = "vfat";
    };
  # Purpose-specific
  fileSystems."/home" = {
    device = "Lpool/purpose/home";
    fsType = "zfs";
  };

  zramSwap = {
    enable = true;
    algorithm = "lz4";
    memoryPercent = 100;
    numDevices = 1; # default
    priority = 5; # default
    swapDevices = 1; # why do I need this?
  };
}
