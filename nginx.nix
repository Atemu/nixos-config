{ config, lib, ... }:

let
  this = config.custom.virtualHosts;

  inherit (lib) mkEnableOption mkOption mkIf mapAttrs' nameValuePair toLower;
  inherit (lib.types) attrsOf submodule nullOr int str;
  inherit (config.lib.custom) concatDomain;
  inherit (config.custom) hostName;
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
              The subdomain to place this service under.
            '';
          };

          onPrimaryDomain = mkEnableOption "place this service on {option}`custom.primaryDomain}";

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

          TLS = {
            enable = mkEnableOption "TLS certificates via ACME" // mkOption {
              default = true;
            };
          };

          localPort = mkOption {
            default = 80;
            type = int;
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
    # Enable if there are hosts declared
    enable = this != { };
  in {
    services.nginx.enable = mkIf enable true;
    custom.acme.enable = enable;

    networking.firewall.allowedTCPPorts = mkIf enable [ 80 443 ];

    services.nginx.virtualHosts = mapAttrs' (name: host:
      nameValuePair host.domain (mkIf (host.TLS.enable || !host.onlyEnableTLS) {
        forceSSL = true;
        useACMEHost = host.domain;
        locations."/" = mkIf (!host.onlyEnableTLS) {
          proxyPass = "http://localhost:${toString host.localPort}";
        };
      })
    ) this;

    custom.acme.domains = mapAttrs' (name: host:
      nameValuePair host.domain (mkIf host.TLS.enable { })
    ) this;
  };
}
