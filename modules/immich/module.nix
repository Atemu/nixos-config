{ config, lib, pkgs, ... }:

let
  this = config.custom.immich;
  inherit (lib) mkEnableOption mkOption types mkIf pipe filterAttrs mapAttrs genAttrs optional;
  inherit (config.lib.custom) concatDomain;
in

{
  options.custom.immich = {
    enable = mkEnableOption "my Immich setup";

    onPrimaryDomain = mkEnableOption "place piped services on primary domain";
  };

  config = mkIf this.enable {
    custom.docker-compose.immich = {
      directory = let
        yml = pkgs.fetchurl {
          url = "https://github.com/immich-app/immich/releases/download/v1.93.3/docker-compose.yml";
          hash = "sha256-EpEDmLI7VTxzg8opyyrvyYqKnF8b6D7NxtEQupdPu7g=";
        };
      in
        pkgs.runCommand "immich-docker" { } ''
          mkdir -p $out
          ln -s ${yml} $out/docker-compose.yml
          ln -s ${./.env} $out/.env
        '';
    };

    custom.virtualHosts.immich = {
      localPort = 2283;
      inherit (this) onPrimaryDomain;
    };
  };
}
