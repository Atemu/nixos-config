# This file contains the configuration of disks and storage
let
  rootPool = mkUuid "75bf8354-257d-4164-8936-ab94951d70c5"; # UUID of the root pool

  # TODO put in custom lib
  mkUuid = uuid: "/dev/disk/by-uuid/${uuid}";
  mkMount = subvol: {
    device = rootPool;
    fsType = "btrfs";
    options = [ "compress-force=zstd:1" "subvol=${subvol}" ];
  };
in {
  boot.loader.grub.devices = [ "nodev" ];
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.useOSProber = true;

  fileSystems = {
    # TODO refactor into custom.fs.tmp = true and custom.fs.boot.uuid = "CC0D-7BC2";
    "/tmp" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "size=50%" "nosuid" "nodev" "nodev" "mode=1777" ]; # systemd default security options
    };
    "/boot" = {
      device = mkUuid "CC0D-7BC2";
      fsType = "vfat";
      options = [ "umask=077" ];
    };

    "/" = mkMount "@";
    "/nix" = mkMount "@nix";
    "/home" = mkMount "@home";
  };
}
