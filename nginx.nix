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
        };
      }));
    };
  };

  config = let
    # Enable if there are hosts declared
    enable = this != { };
  in {
    services.nginx.enable = enable;
    custom.acme.enable = enable;

    networking.firewall.allowedTCPPorts = mkIf enable [ 80 443 ];

    services.nginx.virtualHosts = mapAttrs' (name: host: let
      domain = concatDomain [ host.subdomain host.baseDomain ];
    in
      nameValuePair domain {
        forceSSL = true;
        # enableACME = true;
        useACMEHost = domain;
        locations."/" = {
          proxyPass = "http://localhost:${toString host.localPort}";
        };
      }
    ) this;

    custom.acme.domains = mapAttrs' (name: host:
      nameValuePair (concatDomain [ host.subdomain host.baseDomain ]) (mkIf host.TLS.enable { })
    ) this;
  };
}
