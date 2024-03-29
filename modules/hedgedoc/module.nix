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

    services.hedgedoc.settings = {
      inherit (config.custom.virtualHosts.hedgedoc) domain;

      # Required to use HTTPS through reverse proxy
      protocolUseSSL = true;

      # Allow creation of any custom hedgedoc URL
      allowFreeURL = true;

      # Don't need it.
      allowGravatar = false;
    };

    custom.virtualHosts.hedgedoc = {
      localPort = config.services.hedgedoc.settings.port;
    };
  };
}
