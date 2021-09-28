{ config, lib, ... }:

with lib;

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
      default = lib.warn "No `custom.fs.boot` device declared, proceed with caution!" null;
    };

    btrfs = {
      enable = mkEnableOption "my default btrfs layout";

      device = mkOption {
        description = ''
          The device to mount the main pool from
        '';
        default = lib.warn "No `custom.fs.btrfs.device` declared, proceed with caution!" null;
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
