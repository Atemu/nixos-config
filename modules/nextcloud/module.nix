{
  config,
  lib,
  pkgs,
  ...
}:

let
  this = config.custom.nextcloud;
in

{
  options.custom.nextcloud = {
    enable = lib.mkEnableOption "my custom nextcloud config";
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
      package = pkgs.nextcloud28;
      hostName = config.custom.virtualHosts.nextcloud.domain;
      https = true;
      config = {
        adminpassFile = toString (pkgs.writeText "password" "none");
      };
      maxUploadSize = "0"; # Don't limit it.
    };

    custom.virtualHosts.nextcloud = {
      onlyEnableTLS = true;
    };
  };
}
