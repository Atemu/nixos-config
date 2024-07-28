{ lib, config, ... }:

let
  this = config.custom.hedgedoc;
in

{
  options.custom.hedgedoc = {
    enable = lib.mkEnableOption "my custom hedgedoc";
  };

  config = lib.mkIf this.enable {
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
