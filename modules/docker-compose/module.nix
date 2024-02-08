{ config, lib, pkgs, ... }:

let
  this = config.custom.docker-compose;

  inherit (lib) mkOption mkIf mapAttrs' nameValuePair mapAttrsToList;
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

  config = mkIf (this != { }) (let
    # A jq query to transform the docker-compose.yml.
    #
    # Never restart these services; they should be ephemeral.
    #
    # Log driver needs to be json-file in order for the individual
    # containers to not log to syslog but still have logs in the output
    # of docker compose.
    query = ''.services = (.services | map_values(.restart = "no") | map_values(.logging = { "driver": "json-file" }))'';

    sanitise = directory: pkgs.runCommand "docker-compose-sanitised" { } ''
      cp -rs ${directory} $out
      chmod +w -R $out/
      rm $out/docker-compose.yml

      ${lib.getExe pkgs.yq} -Y '${query}' ${directory}/docker-compose.yml > $out/docker-compose.yml
    '';

    runIn = directory: command: "${lib.getExe pkgs.docker} compose -f ${sanitise directory}/docker-compose.yml ${command}";
  in {
    virtualisation.docker.enable = true;

    systemd.services = mapAttrs' (name: value:
      nameValuePair "docker-compose-${name}" {
        serviceConfig = let
          run = runIn value.directory;
        in {
          # Stop services before in case they're running
          ExecStartPre = run "down";
          ExecStart = run "up --abort-on-container-exit";

          ExecStop = run "down";

          Restart = "on-failure";
        };
        path = [ pkgs.docker ];

        requires = [ "docker.service" ];
        wantedBy = [ "multi-user.target" ];
      }
    ) this;

    environment.systemPackages = mapAttrsToList
      (name: value: pkgs.writeShellScriptBin "docker-compose-${name}" (runIn value.directory ''"$@"''))
      this;
  });
}
