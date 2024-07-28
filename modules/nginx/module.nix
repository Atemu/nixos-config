{ config, lib, pkgs, ... }:

let
  this = config.custom.virtualHosts;

  inherit (config.lib.custom) concatDomain;
  inherit (config.networking) hostName;
  inherit (config.custom.acme) primaryDomain;
in

{
  options.custom = {
    virtualHosts = lib.mkOption {
      description = ''
        A declaration of virtual hosts provided on this machine.
      '';
      default = { };
      type = lib.types.attrsOf (lib.types.submodule ({ name, config, ... }: {
        options = {
          subdomain = lib.mkOption {
            default = name;
            defaultText = "Use the <name>.";
            type = with lib.types; nullOr str;
            description = ''
              The subdomain to place this service under. Set to `null` or `""` to configure the baseDomain.
            '';
          };

          onPrimaryDomain = lib.mkEnableOption "place this service on {option}`custom.primaryDomain`";

          baseDomain = lib.mkOption {
            default = (
              if config.onPrimaryDomain
              then primaryDomain
              else concatDomain [ (lib.toLower hostName) primaryDomain ]
            );
          };

          domain = lib.mkOption {
            default = concatDomain [ config.subdomain config.baseDomain ];
            type = lib.types.str;
            description = ''
              The full domain to use for this virtualHost. Should be left on default.
            '';
          };

          ACMEHost = lib.mkOption {
            default = if config.onPrimaryDomain then config.domain else config.baseDomain;
            defaultText = "A specific {option}`domain` if the host is {option}`onPrimaryDomain` or a wildcard on the host's {option}`baseDomain`.";
            type = lib.types.str;
            description = ''
              The host to use for the ACME cert.
            '';
          };

          TLS = {
            enable = lib.mkEnableOption "TLS certificates via ACME" // lib.mkOption {
              default = true;
            };
          };

          localPort = lib.mkOption {
            default = 80;
            type = lib.types.port;
            description = ''
              Local port that should be addressed when this subdomain is called.
              If the service listens on `localhost:1234`, set this to `1234`.
            '';
          };

          onlyEnableTLS = lib.mkEnableOption ''
            only enable TLS settings for this virtualHost.
            This is useful to when using this module to override an external nginx configuration.
          '';
        };
      }));
    };
  };

  config = let
    validHosts = lib.filterAttrs (name: host: host.TLS.enable || !host.onlyEnableTLS) this;
  in lib.mkIf (validHosts != { }) {
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

    services.nginx.virtualHosts = (lib.mapAttrs' (name: host:
      lib.nameValuePair host.domain {
        forceSSL = true;
        useACMEHost = host.ACMEHost;
        locations."/" = lib.mkIf (!host.onlyEnableTLS) {
          proxyPass = "http://localhost:${toString host.localPort}";
          proxyWebsockets = true; # This is off by default. Don't know why.
        };

        # Optimisations
        quic = true;
        kTLS = true;
      }
    ) validHosts) // {
      # Provide a default virtualHost that captures all misguided requests
      "default" = {
        default = true;
        serverName = "_"; # invalid

        # Required in order to also set the default for HTTPS
        rejectSSL = true;
        quic = true;

        locations."/".return = "404"; # FIXME int after 24.05
      };
    };

    custom.acme.domains = lib.mapAttrs' (name: host:
      lib.nameValuePair host.ACMEHost (lib.mkIf host.TLS.enable {
        wildcard = lib.mkIf (!host.onPrimaryDomain) true;
      })
    ) validHosts;
  };
}
