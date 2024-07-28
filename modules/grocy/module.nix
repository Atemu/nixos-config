{ config, lib, ... }:

let
  this = config.custom.grocy;
in

{
  options.custom.grocy = {
    enable = lib.mkEnableOption "my custom Grocy setup";
  };

  config = lib.mkIf this.enable {
    services.grocy = {
      enable = true;
      hostName = config.custom.virtualHosts.grocy.domain;
      settings = {
        currency = "EUR";
        culture = "en";
        calendar.firstDayOfWeek = 1; # Monday
      };
      # I add TLS myself
      nginx.enableSSL = false;
    };

    custom.virtualHosts.grocy = {
      onlyEnableTLS = true;
    };

    # FIXME Grocy needs a PHP version with OpenSSL 1.1.1?
    nixpkgs.config.permittedInsecurePackages = lib.mkIf (lib.versionOlder lib.trivial.release "23.11") [
      "openssl-1.1.1w"
    ];
  };
}
