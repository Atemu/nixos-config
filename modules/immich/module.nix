{ config, lib, pkgs, ... }:

let
  this = config.custom.immich;
  inherit (lib) mkEnableOption mkOption types mkIf pipe filterAttrs mapAttrs genAttrs optional mkAliasOptionModule;
  inherit (config.lib.custom) concatDomain;
in

{
  options.custom.immich = {
    enable = mkEnableOption "my Immich setup";
  };

  imports = [
    (mkAliasOptionModule [ "custom" "immich" "virtualHost" ] [ "custom" "virtualHosts" "immich" ])
  ];

  config = mkIf this.enable {
    custom.docker-compose.immich = {
      stateDirectory.enable = true;

      env = {
        # You can find documentation for all the supported env variables at https://immich.app/docs/install/environment-variables

        # The location where your uploaded files are stored
        UPLOAD_LOCATION = "/var/lib/immich/"; # The systemd StateDirectory

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
      };

      file = pkgs.fetchurl {
        url = "https://github.com/immich-app/immich/releases/download/v1.97.0/docker-compose.yml";
        hash = "sha256-onNPerC2a65Uy6sAXaU6WMhPJOnWOyq3HaTkL2oixx8=";
      };

      override = {
        services.database = {
          volumes = [
            "\${UPLOAD_LOCATION}/pgdata/:/var/lib/postgresql/data"
          ];
        };
      };
    };

    custom.virtualHosts.immich = {
      localPort = 2283;
    };
  };
}
