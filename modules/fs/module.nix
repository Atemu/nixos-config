{ lib, config, options, ... }:

let
  this = config.custom.fs;

  inherit (lib) mkEnableOption mkOption mkIf genAttrs mkMerge substring;
  inherit (config.lib.custom) mkLabel;
in

{
  options.custom.fs = {
    enable = mkEnableOption "my default filesystems";
    boot = mkOption {
      description = "Device to mount the boot partition from.";
      default = mkLabel (substring 0 11 config.networking.hostName); # FAT32 is shit and only allows 11 chars
    };
    root = mkOption {
      description = "Device to mount the root partition from.";
      default = mkLabel "${config.networking.hostName}-root";
    };

    btrfs = {
      enable = mkEnableOption "my default btrfs layout";

      device = mkOption {
        description = "The device to mount the main pool from ";
        default = config.custom.fs.root;
      };

      newLayout = mkEnableOption "new root layout with /Users and /Volumes inspired by macOS";

      stateVolumes = mkOption {
        description = "Subvolumes to create and mount that contain important state. Only works with newLayout and is additive.";
        default = [ "Users" "Root" ]; # TODO Root should be stateless, a new var subvol should be here instead
      };

      autoSnapshots = {
        enable = mkOption {
          default = this.btrfs.newLayout;
          defaultText = "`config.custom.fs.btrfs.newLayout`";
          description = "Whether to enable automatic snapshotting";
        };

        subvolumes = mkOption {
          description = "The list of subvolumes to auto-snapshot";
          default = this.btrfs.stateVolumes;
          defaultText = "{option}`config.custom.fs.btrfs.stateVolumes`; they are assumed to have state in them that is important enough to warrant snapshots.";
        };
      };
    };

  };

  config = mkIf this.enable {
    fileSystems = {
      "/tmp" = {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [ "size=50%" "nosuid" "nodev" "nodev" "mode=1777" ]; # systemd default security options
      };

      "/boot" = {
        device = this.boot;
        fsType = "vfat";
        options = [ "umask=077" ];
      };
    };

    custom.btrfs.default.device = this.btrfs.device;
    custom.btrfs.default.options = [
      # Is the default nowadays but ensure it
      "space_cache=v2"
      # This discards freed extents asynchronously in the background.
      # No noticeable impact on performance and obviates weekly trims.
      "discard=async"
      # Would update a dir's atime whenever its contents are listed.
      # I don't have a need for that.
      "nodiratime"
    ];
    custom.btrfs.fileSystems = let
      mkMount = subvol: {
        inherit (this.btrfs) device;
        inherit subvol;
      };

      oldLayout = {
        "/" = mkMount "root";
        "/nix" = mkMount "nix";
        "/home" = mkMount "home";
      };
      newLayout = let
        defaultVolumes = {
          "/" = mkMount "Root";
          "/nix" = mkMount "Nix Store";
          "/Users" = mkMount "Users";
          "/System/Volumes" = mkMount "/";
        };

        stateVolumes = map (name: lib.nameValuePair "/Volumes/${name}" (mkMount name)) this.btrfs.stateVolumes;
      in
        defaultVolumes // (lib.listToAttrs stateVolumes);
    in lib.mkIf this.btrfs.enable (if this.btrfs.newLayout then newLayout else oldLayout);

    # We want these to be additive, so we need to set these here rather than as
    # the options' defaults which would get overridden when additional
    # stateVolumes are set elsewhere
    custom.fs.btrfs.stateVolumes = options.custom.fs.btrfs.stateVolumes.default;
    custom.fs.btrfs.autoSnapshots.subvolumes = options.custom.fs.btrfs.autoSnapshots.subvolumes.default;

    # Systemd tries to generate /home by default. It doesn't seem to conflict but better disable that
    environment.etc."tmpfiles.d/home.conf" = lib.mkIf this.btrfs.newLayout { source = "/dev/null"; };
    systemd.tmpfiles.rules = mkIf this.btrfs.newLayout [
      # Create symlinks for backwards compatibility
      "L+ /home - - - - /Users"
    ];

    custom.btrbk = mkIf this.btrfs.autoSnapshots.enable {
      enable = true;

      # autoSnapshots.subvolumes = [ "Foo" "Bar" ] -> subvolume = { Foo = { }; Bar = { }; }
      volume."/System/Volumes".subvolume = genAttrs this.btrfs.autoSnapshots.subvolumes (_: { });
    };
  };
}
