{ lib, config, ... }:

let
  this = config.custom.lib;
in

{
  options.custom.lib = {
    enable = lib.mkEnableOption "my custom library functions";
  };

  config.lib.custom = lib.mkIf this.enable {
    # Makes a by-uuid device out of UUID
    mkUuid = uuid: "/dev/disk/by-uuid/${uuid}";

    # Makes a by-label device out of label
    mkLabel = label: "/dev/disk/by-label/${label}";

    mkPrivateOption = args: lib.mkOption (args // {
      default = lib.warn "Secret not applied, using default${lib.optionalString (args ? default) " (${args.default})"}" args.default;
    });

    concatDomain = lib.flip lib.pipe [
      (lib.filter (n: n != null && n != ""))
      (lib.concatStringsSep ".")
    ];
  };
}
