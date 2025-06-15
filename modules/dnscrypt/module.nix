{
  config,
  lib,
  pkgs,
  ...
}:

let
  this = config.custom.dnscrypt;
in

{
  options.custom.dnscrypt = {
    enable = lib.mkEnableOption "my custom dnscrypt-proxy config";

    passthru = lib.mkOption {
      description = "options to pass through to the regular services.dnscrypt-proxy2";
      default = { };
    };

    listen = lib.mkEnableOption "dnscrypt-proxy should listen on port 53";
  };

  config = lib.mkIf this.enable {
    services.dnscrypt-proxy2 = (
      lib.recursiveUpdate {
        enable = true;

        settings = {
          listen_addresses = if this.listen then [ "0.0.0.0:53" ] else [ "127.0.0.1:53" ];
          ipv6_servers = true;
          server_names = [
            "cloudflare-ipv6"
            "cloudflare"
          ];
          require_dnssec = true;
          require_nolog = true;
          require_nofilter = true;
          lb_strategy = "p2";
          lb_estimator = true;

          cache = false;
        };

        configFile =
          pkgs.runCommand "dnscrypt-proxy.toml"
            {
              json = builtins.toJSON config.services.dnscrypt-proxy2.settings;
              passAsFile = [ "json" ];
            }
            ''
              ${pkgs.remarshal}/bin/toml2json ${pkgs.dnscrypt-proxy2.src}/dnscrypt-proxy/example-dnscrypt-proxy.toml > example.json
              ${pkgs.jq}/bin/jq --slurp add example.json $jsonPath > config.json # merges the two
              ${pkgs.remarshal}/bin/json2toml < config.json > $out
            '';
      } this.passthru
    );

    networking.firewall.allowedUDPPorts = lib.mkIf this.listen [ 53 ];
  };
}
