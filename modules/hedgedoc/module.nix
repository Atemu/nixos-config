{ lib, config, ... }:

let
  inherit (lib) mkEnableOption mkIf;
  this = config.custom.hedgedoc;
in

{
  options.custom.hedgedoc = {
    enable = mkEnableOption "my custom hedgedoc";
  };

  config = mkIf this.enable {
    services.hedgedoc.enable = true;

    services.hedgedoc.settings.domain = config.custom.virtualHosts.hedgedoc.domain;

    custom.virtualHosts.hedgedoc = {
      localPort = config.services.hedgedoc.settings.port;
    };
  };
}
