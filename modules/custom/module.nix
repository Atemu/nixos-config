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

    emacs = mkOption {
      description = "Emacs package to use.";
      # TODO Use { withGTK3 = false; } again
      default = pkgs.emacs29;
      example = pkgs.emacs-nox;
      type = types.package;
      # implemented in packages.nix and desktop.nix
    };
  };

  config = {
    networking.hostName = self.hostName;

    # The hostId is set to the first 8 chars of the sha256 of the hostName
    networking.hostId = substring 0 8 (builtins.hashString "sha256" self.hostName);
  };
}
