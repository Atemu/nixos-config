{ config, lib, ... }:

let
  this = config.custom.acme;
  inherit (config.lib.custom) mkPrivateOption concatDomain;

  example = {
    primaryDomain = "example.com";
    email = "nobody@example.com";
  };
in

{
  options.custom.acme = {
    enable = lib.mkEnableOption "SSL certs via ACME";

    primaryDomain = mkPrivateOption {
      default = example.primaryDomain;

      description = ''
        The base domain name to put sub-domains under.
      '';
    };

    email = mkPrivateOption {
      default = example.email;

      description = ''
        The email address to send to Let's Encrypt.
      '';
    };

    domains = lib.mkOption {
      default = { };
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          wildcard = lib.mkEnableOption "a wildcard cert for this subdomain";
        };
      });
    };
  };

  config = lib.mkIf this.enable {
    security.acme.acceptTerms = true;
    security.acme.defaults = {
      # Use staging server if test values are used
      server = let
        isTestValues = this.primaryDomain == example.primaryDomain || this.email == example.email;
      in lib.mkIf isTestValues (lib.warn
        "ACME test values were used, using staging ACME server."
        "https://acme-staging-v02.api.letsencrypt.org/directory"
      );
      inherit (this) email;

      dnsProvider = "desec";
      # Use deSEC's own DNS server rather than the network's to minimise propagation time
      dnsResolver = "ns1.desec.io:53";

      credentialsFile = "/etc/secrets/acme";
      reloadServices = [ "nginx" ];
      group = "nginx";
    };

    security.acme.certs = lib.mapAttrs' (name: subdomain:
      lib.nameValuePair name {
        domain = if subdomain.wildcard then concatDomain [ "*" name ] else name;
      }
    ) this.domains;
  };
}
