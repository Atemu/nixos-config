{ config, lib, pkgs, ... }:

let
  this = config.custom.virtualHosts;

  inherit (lib) mkEnableOption mkOption mkIf filterAttrs mapAttrs' nameValuePair toLower;
  inherit (lib.types) attrsOf submodule nullOr port str;
  inherit (config.lib.custom) concatDomain;
  inherit (config.networking) hostName;
  inherit (config.custom.acme) primaryDomain;
in

{
  options.custom = {
    virtualHosts = mkOption {
      description = ''
        A declaration of virtual hosts provided on this machine.
      '';
      default = { };
      type = attrsOf (submodule ({ name, config, ... }: {
        options = {
          subdomain = mkOption {
            default = name;
            defaultText = "Use the <name>.";
            type = nullOr str;
            description = ''
              The subdomain to place this service under. Set to `null` or `""` to configure the baseDomain.
            '';
          };

          onPrimaryDomain = mkEnableOption "place this service on {option}`custom.primaryDomain`";

          baseDomain = mkOption {
            default = (
              if config.onPrimaryDomain
              then primaryDomain
              else concatDomain [ (toLower hostName) primaryDomain ]
            );
          };

          domain = mkOption {
            default = concatDomain [ config.subdomain config.baseDomain ];
            type = str;
            description = ''
              The full domain to use for this virtualHost. Should be left on default.
            '';
          };

          ACMEHost = mkOption {
            default = if config.onPrimaryDomain then config.domain else config.baseDomain;
            defaultText = "A specific {option}`domain` if the host is {option}`onPrimaryDomain` or a wildcard on the host's {option}`baseDomain`.";
            type = str;
            description = ''
              The host to use for the ACME cert.
            '';
          };

          TLS = {
            enable = mkEnableOption "TLS certificates via ACME" // mkOption {
              default = true;
            };
          };

          localPort = mkOption {
            default = 80;
            type = port;
            description = ''
              Local port that should be addressed when this subdomain is called.
              If the service listens on `localhost:1234`, set this to `1234`.
            '';
          };

          onlyEnableTLS = mkEnableOption ''
            only enable TLS settings for this virtualHost.
            This is useful to when using this module to override an external nginx configuration.
          '';
        };
      }));
    };
  };

  config = let
    validHosts = filterAttrs (name: host: host.TLS.enable || !host.onlyEnableTLS) this;
  in mkIf (validHosts != { }) {
    services.nginx.enable = true;
    services.nginx.package = pkgs.nginxQuic;
    services.nginx.clientMaxBodySize = "0";
    # Don't see why I shouldn't have these on. If something crops up, I can
    # always disable them individually.
    services.nginx.recommendedProxySettings = true;
    services.nginx.recommendedTlsSettings = true;
    services.nginx.recommendedOptimisation = true;
    services.nginx.recommendedGzipSettings = true;
    services.nginx.recommendedBrotliSettings = true;
    services.nginx.recommendedZstdSettings = true;
    # Reload rather than restart. Don't see why not and it exposes the config
    # file under /etc as a bonus which is great for introspection.
    services.nginx.enableReload = true;

    custom.acme.enable = true;

    networking.firewall.allowedTCPPorts = [ 80 443 ];
    networking.firewall.allowedUDPPorts = [ 80 443 ];

    services.nginx.virtualHosts = mapAttrs' (name: host:
      nameValuePair host.domain {
        forceSSL = true;
        useACMEHost = host.ACMEHost;
        locations."/" = mkIf (!host.onlyEnableTLS) {
          proxyPass = "http://localhost:${toString host.localPort}";
          proxyWebsockets = true; # This is off by default. Don't know why.
        };

        # Optimisations
        quic = true;
        kTLS = true;
      }
    ) validHosts;

    custom.acme.domains = mapAttrs' (name: host:
      nameValuePair host.ACMEHost (mkIf host.TLS.enable {
        wildcard = mkIf (!host.onPrimaryDomain) true;
      })
    ) validHosts;
  };
}
