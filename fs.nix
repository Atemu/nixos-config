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

    btrfs = {
      enable = mkEnableOption "my default btrfs layout";

      device = mkOption {
        description = ''
          The device to mount the main pool from
        '';
        default = config.custom.fs.root;
      };

      newLayout = mkEnableOption "new root layout with /Users and /Volumes inspired by macOS";

      stateVolumes = mkOption {
        description = "Subvolumes to create and mount that contain important state. Only works with newLayout.";
        default = [ ]; # Implemented below
        defaultText = ''`[ "Users" ]` (not overridden addititve when set, only added to)'';
      };

      autoSnapshots = {
        enable = mkOption {
          default = cfg.btrfs.newLayout;
          defaultText = "`config.custom.btrfs.newLayout`";
          description = "Whether to enable automatic snapshotting";
        };

        subvolumes = mkOption {
          description = "The list of subvolumes to auto-snapshot";
          default = [ ]; # Implemented below
          defaultText = "All stateVolumes; they are assumed to have state in them that is important enough to warrant snapshots.";
        };
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
      "/System/Volumes" = mkMount "";
    };
  in lib.mkIf cfg.btrfs.enable (if cfg.btrfs.newLayout then newLayout else oldLayout);

  # We want these to be additive, so we need to set these here rather than as
  # the options' defaults which would get overridden when additional
  # stateVolumes are set elsewhere
  config.custom.fs.btrfs.stateVolumes = [ "Users" ];
  config.custom.fs.btrfs.autoSnapshots.subvolumes = cfg.btrfs.stateVolumes;

  # Systemd tries to generate /home by default. It doesn't seem to conflict but better disable that
  config.environment.etc."tmpfiles.d/home.conf" = lib.mkIf cfg.btrfs.newLayout { source = "/dev/null"; };
  config.systemd.tmpfiles.rules = mkIf cfg.btrfs.newLayout [
    # Create symlinks for backwards compatibility
    "L+ /home - - - - /Users"
    # macOS does this too
    "L+ /Volumes/Root - - - - /"
  ];

  config.custom.btrbk = mkIf cfg.btrfs.autoSnapshots.enable {
    enable = true;

    # autoSnapshots.subvolumes = [ "Foo" "Bar" ] -> subvolume = { Foo = { }; Bar = { }; }
    volume."/System/Volumes".subvolume = genAttrs cfg.btrfs.autoSnapshots.subvolumes (_: { });
  };
}
