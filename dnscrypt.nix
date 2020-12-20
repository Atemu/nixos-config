{ config, lib, pkgs, ... }:

with lib;

let
  self = config.custom.dnscrypt;
in

{
  options.custom.dnscrypt = {
    enable = mkEnableOption "my custom dnscrypt-proxy config";

    passthru = mkOption {
      description = "options to pass through to the regular services.dnscrypt-proxy2";
      default = { };
    };

    listen = mkOption {
      default = false;
      example = true;
      description = "Whether dnscrypt-proxy should listen on port 53";
    };
  };

  config.services.dnscrypt-proxy2 = mkIf self.enable (recursiveUpdate {
    enable = true;

    settings = {
      listen_addresses = if self.listen then [ "0.0.0.0:53" ] else [ "127.0.0.1:53" ];
      ipv6_servers = true;
      require_dnssec = true;
      require_nolog = true;
      require_nofilter = true;
      lb_strategy = "p2";
      lb_estimator = true;
      dnscrypt_ephemeral_keys = true;
      tls_disable_session_tickets = true;
    };

    configFile = pkgs.runCommand "dnscrypt-proxy.toml" {
      json = builtins.toJSON config.services.dnscrypt-proxy2.settings;
      passAsFile = [ "json" ];
    } ''
      ${pkgs.remarshal}/bin/toml2json ${pkgs.dnscrypt-proxy2.src}/dnscrypt-proxy/example-dnscrypt-proxy.toml > example.json
      ${pkgs.jq}/bin/jq --slurp add example.json $jsonPath > config.json # merges the two
      ${pkgs.remarshal}/bin/json2toml < config.json > $out
    '';
  } self.passthru);
  config.networking.firewall.allowedUDPPorts = mkIf self.listen [ 53 ];
}
