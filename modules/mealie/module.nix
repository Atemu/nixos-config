{ lib, config, ... }:

let
  this = config.custom.mealie;
in

{
  options.custom.mealie = {
    enable = lib.mkEnableOption "my mealie setup";
  };

  imports = [
    (lib.mkAliasOptionModule [ "custom" "mealie" "virtualHost" ] [ "custom" "virtualHosts" "mealie" ])
  ];

  config = lib.mkIf this.enable {
    services.mealie.enable = true;

    custom.virtualHosts.mealie = {
      localPort = 9000;
    };

    services.mealie.settings = {
      BASE_URL = config.custom.virtualHosts.mealie.domain;
    };
  };
}
