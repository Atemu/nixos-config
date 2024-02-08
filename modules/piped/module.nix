{ config, lib, pkgs, ... }:

let
  this = config.custom.piped;
  inherit (lib) mkEnableOption mkOption types mkIf pipe filterAttrs mapAttrs genAttrs optional;
  inherit (config.lib.custom) concatDomain;

  baseDomain = config.custom.virtualHosts.piped.domain;
  serviceNames = [ "piped" "pipedapi" "pipedproxy" ];

  hostnames = pipe config.custom.virtualHosts [
    (filterAttrs (n: v: lib.elem n serviceNames))
    (mapAttrs (n: v: v.domain))
  ];
in

{
  options.custom.piped = {
    enable = mkEnableOption "my Piped setup";

    onPrimaryDomain = mkEnableOption "place piped services on primary domain";

    reverseProxy = mkOption {
      default = "nginx";
      type = types.enum [ "nginx" "caddy" ];
      description = "Which reverse proxy to use internally.";
    };

    DBLocation = mkOption {
      default = "piped-data";
      type = types.oneOf [ (types.enum [ "piped-data" ]) types.path ];
      description = "Path to store the database state in. Alternatively, you can use the `piped-data` docker volume.";
    };

    feedFetchHack = mkEnableOption "a hack to force fetching feeds via polling to work around https://github.com/TeamPiped/Piped/issues/707";

    src = mkOption {
      internal = true;
      default = pkgs.fetchFromGitHub {
        owner = "TeamPiped";
        repo = "Piped-Docker";
        rev = "49b98cbeb3a1d8042ccd384b81976793bcd06a53";
        hash = "sha256-NVyMtTd2ZR1Qobm73DYZr6WaWBvcWzj5VYLbaXNCliI=";
      };
    };
    piped-docker = mkOption {
      internal = true;
      default = let
        volumesYAML = pkgs.writers.writeYAML "volumes.yml" {
          volumes = genAttrs ([ "piped-proxy" ] ++ (optional (this.DBLocation == "piped-data") "piped-data")) (n: { name = n; });
        };
      in pkgs.runCommand "piped-docker-configured" { } ''
        cd ${this.src}

        mkdir -p $out/config/
        cp -r template/. $out/config/

        substituteInPlace $out/config/* \
          --replace FRONTEND_HOSTNAME ${hostnames.piped} \
          --replace BACKEND_HOSTNAME ${hostnames.pipedapi} \
          --replace PROXY_HOSTNAME ${hostnames.pipedproxy} \

        substituteInPlace $out/config/docker-compose.*.yml \
          --replace "./data/db" ${this.DBLocation} \

        # volumes: section is borderline broken and I need to add my own
        sed '/^volumes:/Q' $out/config/docker-compose.${this.reverseProxy}.yml > $out/docker-compose.yml
        cat ${volumesYAML} >> $out/docker-compose.yml
      '';
    };
  };

  config = mkIf this.enable {
    custom.docker-compose.piped = {
      directory = this.piped-docker;
    };

    custom.virtualHosts = genAttrs serviceNames (n: {
      localPort = 8080;
      inherit (this) onPrimaryDomain;
    });

    systemd.services.piped-feed-fetch = mkIf this.feedFetchHack {
      script = ''
        ${lib.getExe pkgs.docker} exec -i postgres psql -U piped -d piped -qtAX -c 'select id from public.pubsub;' | while IFS= read -r line; do
          ${lib.getExe pkgs.curl} -k "https://${hostnames.pipedapi}/channel/$line" &> /dev/null
          sleep 1
        done
      '';

      startAt = "hourly";
    };
  };
}
