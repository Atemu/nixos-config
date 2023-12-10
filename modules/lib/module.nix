{ lib, ... }:

let
  inherit (lib) mkOption warn optionalString concatStringsSep;
in

{
  config.lib.custom = {
    # Makes a by-uuid device out of UUID
    mkUuid = uuid: "/dev/disk/by-uuid/${uuid}";

    # Makes a by-label device out of label
    mkLabel = label: "/dev/disk/by-label/${label}";

    mkPrivateOption = args: mkOption (args // {
      default = warn "Secret not applied, using default${optionalString (args ? default) " (${args.default})"}" args.default;
    });

    concatDomain = concatStringsSep ".";
  };
}
