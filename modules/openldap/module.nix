{ config, lib, ... }:

let
  this = config.custom.ldap;
in

{
  options.custom.ldap = {
    enable = lib.mkEnableOption "my custom ldap setup";
  };

  config = lib.mkIf this.enable {
    services.openldap = {
      enable = true;
    };
    custom.virtualHosts.ldap = {
      localPort = 9091;
    };
  };
}
