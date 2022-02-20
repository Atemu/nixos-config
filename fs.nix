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
      default = mkLabel "${substring 0 11 config.custom.hostName}"; # FAT32 is shit and only allows 11 chars
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
        default = mkLabel "${config.custom.fs.root}";
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
  config.custom.btrfs.default.options = [ "space_cache=v2" ];
  config.custom.btrfs.fileSystems = let
    mkMount = subvol: {
      inherit (cfg.btrfs) device;
      inherit subvol;
    };
  in lib.mkIf cfg.btrfs.enable {
    "/" = mkMount "root";
    "/nix" = mkMount "nix";
    "/home" = mkMount "home";
  };
}