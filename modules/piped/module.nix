{
  config,
  lib,
  pkgs,
  ...
}:

let
  this = config.custom.piped;

  serviceNames = [
    "piped"
    "pipedapi"
    "pipedproxy"
  ];

  hostnames = lib.pipe config.custom.virtualHosts [
    (lib.filterAttrs (n: v: lib.elem n serviceNames))
    (lib.mapAttrs (n: v: v.domain))
  ];
in

{
  options.custom.piped = {
    enable = lib.mkEnableOption "my Piped setup";

    onPrimaryDomain = lib.mkEnableOption "place piped services on primary domain";

    reverseProxy = lib.mkOption {
      default = "nginx";
      type = lib.types.enum [
        "nginx"
        "caddy"
      ];
      description = "Which reverse proxy to use internally.";
    };

    DBLocation = lib.mkOption {
      default = "piped-data";
      type = lib.types.oneOf [
        (lib.types.enum [ "piped-data" ])
        lib.types.path
      ];
      description = "Path to store the database state in. Alternatively, you can use the `piped-data` docker volume.";
    };

    feedFetchHack = lib.mkEnableOption "a hack to force fetching feeds via polling to work around https://github.com/TeamPiped/Piped/issues/707";

    src = lib.mkOption {
      internal = true;
      default = pkgs.fetchFromGitHub {
        owner = "TeamPiped";
        repo = "Piped-Docker";
        rev = "49b98cbeb3a1d8042ccd384b81976793bcd06a53";
        hash = "sha256-NVyMtTd2ZR1Qobm73DYZr6WaWBvcWzj5VYLbaXNCliI=";
      };
    };
    piped-docker = lib.mkOption {
      internal = true;
      default =
        let
          volumesYAML = pkgs.writers.writeYAML "volumes.yml" {
            volumes =
              lib.genAttrs ([ "piped-proxy" ] ++ (lib.optional (this.DBLocation == "piped-data") "piped-data"))
                (n: {
                  name = n;
                });
          };
        in
        pkgs.runCommand "piped-docker-configured" { } ''
          cd ${this.src}

          mkdir -p $out/config/
          cp -r template/. $out/config/

          substituteInPlace $out/config/* \
            --replace FRONTEND_HOSTNAME ${hostnames.piped} \
            --replace BACKEND_HOSTNAME ${hostnames.pipedapi} \
            --replace PROXY_HOSTNAME ${hostnames.pipedproxy} \

          substituteInPlace $out/config/docker-compose.*.yml \
            --replace "./data/db" ${this.DBLocation} \

          # The nginx Docker image creates symlinks to stdout in the default locations
          # TODO write to some persistent volume with log rotation instead
          substituteInPlace $out/config/nginx.conf \
            --replace "/var/log/nginx/access.log" "/var/log/nginx/access-actual.log" \

          # volumes: section is borderline broken and I need to add my own
          sed '/^volumes:/Q' $out/config/docker-compose.${this.reverseProxy}.yml > $out/docker-compose.yml
          cat ${volumesYAML} >> $out/docker-compose.yml
        '';
    };
  };

  config = lib.mkIf this.enable {
    custom.docker-compose.piped = {
      directory = this.piped-docker;
      # Watchtower kills my services. STOP IT.
      override.services.watchtower.deploy.replicas = 0;
    };

    custom.virtualHosts = lib.genAttrs serviceNames (n: {
      localPort = 8080;
      inherit (this) onPrimaryDomain;
    });

    systemd.services.piped-feed-fetch = lib.mkIf this.feedFetchHack {
      script =
        let
          inherit (config.custom.docker-compose.piped) wrapperScript;
          psql = cmd: "${lib.getExe wrapperScript} exec -i postgres psql -U piped -d piped -qtAX -c '${cmd}'";
        in
        ''
            ${psql "select id from public.pubsub;"} | while IFS= read -r line; do
            ${lib.getExe pkgs.curl} -k "https://${hostnames.pipedapi}/channel/$line" &> /dev/null
            sleep 1
          done
        '';

      startAt = "hourly";
    };
  };
}
