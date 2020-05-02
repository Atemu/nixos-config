{
  fileSystems."/" =
    { device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
      fsType = "ext4";
    };
  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/2178-694E";
      fsType = "vfat";
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
