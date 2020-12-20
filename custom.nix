{ lib, config, pkgs, ... }:

with lib;

let
  self = config.custom;
in

{
  options.custom = {
    hostName = mkOption {
      description = "The name of the host whose config to build.";
      default = "HEPHAISTOS";
      example = "PLATON";
      type = types.str;
    };

    withPackages = mkOption {
      description = "Whether to include system packages.";
      default = true;
      example = false;
      type = types.bool;
      # FIXME implemented in packages.nix for now
    };
  };

  config = {
    networking.hostName = self.hostName;

    # The hostId is set to the crc32 of the hostName in hex
    networking.hostId = builtins.readFile (
      pkgs.runCommand "mkHostId" {} ''
        printf '%X' $(printf "${self.hostName}" | cksum | cut -d ' '  -f1) > $out
      ''
    );
  };
}
