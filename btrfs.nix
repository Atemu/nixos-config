{ config, lib, ... }:

with lib;

let
  cfg = config.custom.btrfs;
in

{
  options.custom.btrfs = {
    fileSystems = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          device = mkOption {
            description = ''
              The device to mount
            '';
          };

          compress = {
            # TODO Make this on by default
            enable = mkOption {
              description = ''
                Whether to enabe btrfs filesystem compression
              '';
              default = true;
            };

            algorithm = mkOption {
              description = ''
                The compression algorith to use
              '';
              default = "zstd";
            };

            level = mkOption {
              description = ''
                The compression level to use
              '';
              default = 1;
            };

            force = mkOption {
              description = ''
                Whether to force compression or leave btrfs to decide what's compressible and what isn't
              '';
              default = true;
            };
          };

          subvol = mkOption {
            description = ''
              Subvolume to mount. Null means default subvol
            '';
            default = null;
          };
          options = mkOption {
            description = ''
              Mount options too add on
            '';
            default = [ ];
          };
        };
      });
      default = { };
      example = literalExample ''
        {
          "/data" = {
            device = "/dev/disk/by-id/ata-foo";
            subvolume = "data";
            compress.level = 10;
            extraOptions = [ "autodefrag" ];
          };
          "/home" = {
            device = "/dev/disk/by-id/ata-foo";
            subvolume = "home";
            compress = {
              force = false;
              level = 2;
            };
          };
        };
      '';
      description = ''
        Btrfs fileSystems, declared similar to NixOS' `fileSystems`.
      '';
    };
  };

  config.fileSystems = mapAttrs (_: fileSystem: {
    fsType = "btrfs";

    inherit (fileSystem) device;

    options = with fileSystem; let
      compressArg = with compress;
        optional enable "compress${optionalString force "-force"}=${algorithm + optionalString (level != null) ":${toString level}"}";
      subvolArg = optional (subvol != null) "subvol=${subvol}";
    in compressArg ++ subvolArg ++ fileSystem.options;
  }) cfg.fileSystems;
}
