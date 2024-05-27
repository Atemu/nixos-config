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
        IMMICH_VERSION = "v1.105.1";

        # Connection secret for postgres. You should change it to a random password
        DB_PASSWORD = "postgres";

        # The values below this line do not need to be changed
        ###################################################################################
        DB_HOSTNAME = "immich_postgres";
        DB_USERNAME = "postgres";
        DB_DATABASE_NAME = "immich";

        REDIS_HOSTNAME = "immich_redis";

        DB_DATA_LOCATION = "/var/lib/postgresql/data/";
      };

      file = pkgs.fetchurl {
        # TODO Put this in a sort of package
        url = "https://github.com/immich-app/immich/releases/download/v1.105.1/docker-compose.yml";
        hash = "sha256-e6ApYlL8E5qntTpuEnAxDrNh8n5c0v2lkI8hAlygcsE=";
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
