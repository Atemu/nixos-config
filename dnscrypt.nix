{ config, pkgs, ... }:

{
  services.dnscrypt-proxy2.enable = true;

  services.dnscrypt-proxy2.settings = {
    ipv6_servers = true;
    require_dnssec = true;
    require_nolog = true;
    require_nofilter = true;
    lb_strategy = "p2";
    lb_estimator = true;
    dnscrypt_ephemeral_keys = true;
    tls_disable_session_tickets = true;
  };

  services.dnscrypt-proxy2.configFile = pkgs.runCommand "dnscrypt-proxy.toml" {
    json =
      let
        settings = builtins.fromJSON (
          builtins.readFile (
            pkgs.runCommand "example-dnscrypt-proxy.json" {} ''
              ${pkgs.remarshal}/bin/toml2json ${pkgs.dnscrypt-proxy2.src}/dnscrypt-proxy/example-dnscrypt-proxy.toml > $out
            ''
          )
        ) // config.services.dnscrypt-proxy2.settings;
      in
        builtins.toJSON settings;
    passAsFile = [ "json" ];
  } ''
    ${pkgs.remarshal}/bin/json2toml < $jsonPath > $out
  '';
}
