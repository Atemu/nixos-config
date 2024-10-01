{ config, lib, pkgs, ... }:

let
  this = config.custom.immich;
  version = "v1.116.2";
in

{
  options.custom.immich = {
    enable = lib.mkEnableOption "my Immich setup";

    libraryDir = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      description = ''
        Where the library data should be stored. The location will be bind-mounted.

        Set to null to not set a library directory.
      '';
    };
  };

  imports = [
    (lib.mkAliasOptionModule [ "custom" "immich" "virtualHost" ] [ "custom" "virtualHosts" "immich" ])
  ];

  config = lib.mkIf this.enable {
    assertions = [
        {
          assertion = lib.versionAtLeast config.virtualisation.docker.package.version "25.0";
          message = ''
            Docker engine >= 25 is required for Immich
          '';
        }
    ];
    virtualisation.docker.package = lib.mkDefault pkgs.docker_25;

    custom.docker-compose.immich = {
      stateDirectory.enable = true;

      env = {
        # You can find documentation for all the supported env variables at https://immich.app/docs/install/environment-variables

        # The location where your uploaded files are stored
        UPLOAD_LOCATION = "/var/lib/immich/"; # The systemd StateDirectory

        # The Immich version to use. You can pin this to a specific version like "v1.71.0"
        IMMICH_VERSION = version;

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
        url = "https://github.com/immich-app/immich/releases/download/${version}/docker-compose.yml";
        hash = "sha256-axp3iW9KcO5RT8SbDdzIR7rIT+vlrf8dmUHGrfIOxws=";
      };

      override = {
        services.database = {
          volumes = [
            "\${UPLOAD_LOCATION}/pgdata/:/var/lib/postgresql/data"
          ];
        };
      };

      service.unitConfig.RequiresMountsFor = lib.mkIf (this.libraryDir != null) [ this.libraryDir ];
    };

    custom.virtualHosts.immich = {
      localPort = 2283;
    };

    fileSystems."/var/lib/immich/library" = lib.mkIf (this.libraryDir != null) {
      device = this.libraryDir;
      options = [ "bind" ];
    };
  };
}
