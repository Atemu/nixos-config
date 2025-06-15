{
  config,
  lib,
  pkgs,
  ...
}:

let
  this = config.custom.nextcloud;
  ncDomain = config.custom.virtualHosts.nextcloud.domain;
in

{
  options.custom.nextcloud = {
    enable = lib.mkEnableOption "my custom nextcloud config";
    code.enable = lib.mkEnableOption "collabora CODE via Docker";
  };

  imports = [
    (lib.mkAliasOptionModule
      [
        "custom"
        "nextcloud"
        "virtualHost"
      ]
      [
        "custom"
        "virtualHosts"
        "nextcloud"
      ]
    )
  ];

  config = lib.mkIf this.enable {
    services.nextcloud = {
      enable = true;
      package = pkgs.nextcloud31;
      hostName = ncDomain;
      https = true;
      config = {
        adminpassFile = toString (pkgs.writeText "password" "none");
        dbtype = "pgsql";
      };
      database.createLocally = true;
      maxUploadSize = "0"; # Don't limit it.
      phpOptions = {
        # This is set to maxUploadSize but if it's 0, well....
        memory_limit = lib.mkForce "512M"; # Recommended limit
      };

      extraAppsEnable = true;
      extraApps = {
        inherit (config.services.nextcloud.package.packages.apps)
          richdocuments
          calendar
          contacts
          tasks
          ;
      };
    };

    custom.virtualHosts.nextcloud = {
      onlyEnableTLS = true;
    };

    virtualisation.oci-containers.containers.collabora = {
      image = "docker.io/collabora/code";
      ports = [ "9980:9980" ];
      autoStart = true;
      environment = {
        # This limits it to this NC instance AFAICT
        aliasgroup1 = "https://${ncDomain}:443";
        # Must disable SSL as it's behind a reverse proxy
        extra_params = "--o:ssl.enable=false";
      };
    };

    custom.virtualHosts.collaboracode = {
      localPort = 9980;
      inherit (config.custom.virtualHosts.nextcloud) onPrimaryDomain;
    };
  };
}
