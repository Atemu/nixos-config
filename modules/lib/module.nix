{ lib, config, ... }:

let
  inherit (lib) mkEnableOption mkOption mkIf warn optionalString flip pipe filter concatStringsSep;
  this = config.custom.lib;
in

{
  options.custom.lib = {
    enable = mkEnableOption "my custom library functions";
  };

  config.lib.custom = mkIf this.enable {
    # Makes a by-uuid device out of UUID
    mkUuid = uuid: "/dev/disk/by-uuid/${uuid}";

    # Makes a by-label device out of label
    mkLabel = label: "/dev/disk/by-label/${label}";

    mkPrivateOption = args: mkOption (args // {
      default = warn "Secret not applied, using default${optionalString (args ? default) " (${args.default})"}" args.default;
    });

    concatDomain = flip pipe [
      (filter (n: n != null && n != ""))
      (concatStringsSep ".")
    ];
  };
}
