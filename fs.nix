{ config, lib, ... }:

with lib;
with config.lib.custom;

let
  cfg = config.custom.fs;
in

{
  options.custom.fs = {
    enable = mkEnableOption "my default filesystems";
    boot = mkOption {
      description = ''
        Device to mount the boot partition from.
      '';
      default = mkLabel (substring 0 11 config.custom.hostName); # FAT32 is shit and only allows 11 chars
    };
    root = mkOption {
      description = ''
        Device to mount the root partition from.
      '';
      default = mkLabel "${config.custom.hostName}-root";
    };

    newLayout = mkEnableOption "new root layout with /Users and /Volumes inspired by macOS";

    btrfs = {
      enable = mkEnableOption "my default btrfs layout";

      device = mkOption {
        description = ''
          The device to mount the main pool from
        '';
        default = config.custom.fs.root;
      };
    };

  };

  config.fileSystems = mkIf cfg.enable {
    "/tmp" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "size=50%" "nosuid" "nodev" "nodev" "mode=1777" ]; # systemd default security options
    };

    "/boot" = {
      device = cfg.boot;
      fsType = "vfat";
      options = [ "umask=077" ];
    };
  };

  config.custom.btrfs.default.device = cfg.btrfs.device;
  config.custom.btrfs.default.options = [ "space_cache=v2" "discard=async" ];
  config.custom.btrfs.fileSystems = let
    mkMount = subvol: {
      inherit (cfg.btrfs) device;
      inherit subvol;
    };

    oldLayout = {
      "/" = mkMount "root";
      "/nix" = mkMount "nix";
      "/home" = mkMount "home";
    };
    newLayout = {
      "/" = mkMount "Root";
      "/nix" = mkMount "Nix Store";
      "/Users" = mkMount "Users";
      "/Volumes/Data" = mkMount "";
    };
  in lib.mkIf cfg.btrfs.enable (if cfg.newLayout then newLayout else oldLayout);

  # Systemd tries to generate /home by default. It doesn't seem to conflict but better disable that
  config.environment.etc."tmpfiles.d/home.conf".source = lib.mkIf cfg.newLayout "/dev/null";
  config.systemd.tmpfiles.rules = mkIf cfg.newLayout [
    # Create a symlink for backwards compatibility
    "L+ /home - - - - /Users"
    # macOS does this too
    "L+ /Volumes/Root - - - - /"
  ];
}
