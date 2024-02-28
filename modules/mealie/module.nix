{ lib, config, ... }:

let
  this = config.custom.mealie;
  inherit (lib) mkEnableOption mkAliasOptionModule mkIf;
in

{
  options.custom.mealie = {
    enable = mkEnableOption "my mealie setup";
  };

  imports = [
    (mkAliasOptionModule [ "custom" "mealie" "virtualHost" ] [ "custom" "virtualHosts" "mealie" ])
  ];

  config = mkIf this.enable {
    services.mealie.enable = true;

    custom.virtualHosts.mealie = {
      localPort = 9000;
    };

    services.mealie.settings = {
      BASE_URL = config.custom.virtualHosts.mealie.domain;
    };
  };
}
