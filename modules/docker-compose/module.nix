{ config, lib, pkgs, ... }:

let
  this = config.custom.docker-compose;

  inherit (lib) mkOption mkIf mapAttrs' nameValuePair;
  inherit (lib.types) attrsOf submodule nullOr path;
in

{
  options.custom.docker-compose = mkOption {
    default = { };
    type = attrsOf (submodule ({ name, config, ... }: {
      options = {
        directory = mkOption {
          default = (
            if config.file != null then
              pkgs.runCommand "docker-compose-${name}" { } ''
                mkdir -p $out/
                ln -s ${config.file} $out/docker-compose.yml
              ''
            else
              throw "You must provide a docker-compose.yml (or directory containing it) for the ${name} docker-compose service."
          );
          defaultText = "{option}`file if it is set.";
          type = path;
        };
        file = mkOption {
          default = null;
          type = nullOr path;
          description = "The path to a docker-compose.yml.";
        };
      };
    }));
  };

  config = mkIf (this != { }) {
    virtualisation.docker.enable = true;

    systemd.services = mapAttrs' (name: value:
      nameValuePair "docker-compose-${name}" {
        serviceConfig = let
          run = command: "${lib.getExe pkgs.docker} compose -f ${value.directory}/docker-compose.yml ${command}";
        in {
          # Stop services before in case they're running
          ExecStartPre = run "down";
          # Run with -d to prevent double logs
          ExecStart = run "up -d";
          Type = "oneshot";
          RemainAfterExit = "yes"; # Don't immediately run ExitStop

          ExecStop = run "down";
        };
        path = [ pkgs.docker ];

        requires = [ "docker.socket" ];
        wantedBy = [ "multi-user.target" ];
      }
    ) this;
  };
}
