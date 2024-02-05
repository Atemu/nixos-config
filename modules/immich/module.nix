{ config, lib, pkgs, ... }:

let
  this = config.custom.immich;
  inherit (lib) mkEnableOption mkOption types mkIf pipe filterAttrs mapAttrs genAttrs optional;
  inherit (config.lib.custom) concatDomain;
in

{
  options.custom.immich = {
    enable = mkEnableOption "my Immich setup";

    stateDirectory = mkOption {
      default = "/var/lib/immich/";
    };

    onPrimaryDomain = mkEnableOption "place piped services on primary domain";
  };

  config = mkIf this.enable {
    custom.docker-compose.immich = {
      stateDirectory.enable = true;

      directory = let
        yml = pkgs.fetchurl {
          url = "https://github.com/immich-app/immich/releases/download/v1.93.3/docker-compose.yml";
          hash = "sha256-EpEDmLI7VTxzg8opyyrvyYqKnF8b6D7NxtEQupdPu7g=";
        };

        env = pkgs.writeText "env" (lib.generators.toKeyValue { } {
          # You can find documentation for all the supported env variables at https://immich.app/docs/install/environment-variables

          # The location where your uploaded files are stored
          UPLOAD_LOCATION = this.stateDirectory;

          # The Immich version to use. You can pin this to a specific version like "v1.71.0"
          IMMICH_VERSION = "release";

          # Connection secret for postgres. You should change it to a random password
          DB_PASSWORD = "postgres";

          # The values below this line do not need to be changed
          ###################################################################################
          DB_HOSTNAME = "immich_postgres";
          DB_USERNAME = "postgres";
          DB_DATABASE_NAME = "immich";

          REDIS_HOSTNAME = "immich_redis";
        });

      in
        pkgs.runCommand "immich-docker" { } ''
          mkdir -p $out
          ln -s ${yml} $out/docker-compose.yml
          ln -s ${env} $out/.env
        '';
    };

    custom.virtualHosts.immich = {
      localPort = 2283;
      inherit (this) onPrimaryDomain;
    };
  };
}
