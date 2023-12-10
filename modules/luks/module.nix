{ config, lib, ... }:

let
  cfg = config.custom.luks;
  labelNumber = lib.types.ints.between 00 99;
in

{
  options.custom.luks = with lib; {
    autoDevices = mkOption {
      type = labelNumber;
      default = 0;
      description = ''
        How many LUKS device labels to generate automatically

        Generates from number = 01 onwards in the pattern of "''${hostName}-crypt''${number}"
      '';
    };
    devices = mkOption {
      type = types.listOf (labelNumber);
      default = [ ];
      description = ''
        Same as `autoDevices` but with manually specified numbers. Union-merged with `autoDevices` when both are declared.
      '';
    };
  };

  config = {
    boot.initrd.luks.devices = let
      # 0 -> "HEPHAISTOS-crypt00"
      # 29 -> "HEPHAISTOS-crypt29"
      nameForNumber = labelNumber: let
        digits = toString labelNumber;
        twoDigits = if labelNumber < 10 then "0${digits}" else digits;
      in
        "${config.custom.hostName}-crypt${twoDigits}";
      names = lib.genList nameForNumber cfg.autoDevices ++ map nameForNumber cfg.devices;
    in
      lib.genAttrs names (name: {
        device = config.lib.custom.mkLabel name;
        allowDiscards = true; # Not part of my threat model
        bypassWorkqueues = true; # Better performance https://blog.cloudflare.com/speeding-up-linux-disk-encryption/
      }
    );
  };
}
