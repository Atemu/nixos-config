{
  # Use the extlinux bootloader instead of GRUB
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.grub.enable = false;

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
      fsType = "ext4";
    };
  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/2178-694E";
      fsType = "vfat";
    };
}
