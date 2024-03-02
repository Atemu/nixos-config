{ config, lib, pkgs, ... }:

let
  this = config.custom.docker-compose;

  inherit (lib) mkOption mkEnableOption mkIf mapAttrs' nameValuePair mapAttrsToList;
  inherit (lib.types) attrsOf submodule nullOr attrs path;

  # A jq query to transform the docker-compose.yml.
  #
  # Never restart these services; they should be ephemeral.
  #
  # Log driver needs to be json-file in order for the individual
  # containers to not log to syslog but still have logs in the output
  # of docker compose.
  query = ''.services = (.services | map_values(.restart = "no") | map_values(.logging = { "driver": "json-file" }))'';

  sanitise = value: pkgs.runCommand "docker-compose-sanitised" { } (''
    cp -rs ${value.directory} $out
    chmod +w -R $out/
    rm $out/docker-compose.yml
  '' + lib.optionalString (value.override != null) ''
    ln -sfn ${pkgs.writers.writeYAML "docker-compose.override.yml" value.override} $out/docker-compose.override.yml
  '' + lib.optionalString (value.env != null) ''
    ln -sfn ${(pkgs.formats.keyValue { }).generate ".env" value.env} $out/.env
  '' + ''
    ${lib.getExe pkgs.yq} -Y '${query}' ${value.directory}/docker-compose.yml > $out/docker-compose.yml
  '');

  runConfig = value: command: "${lib.getExe pkgs.docker} compose --project-directory ${sanitise value} ${command}";
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
          defaultText = "{option}`file` if it is set.";
          type = path;
          description = ''
            A directory containing a docker-compose.yml.

            If the {option}`file` or {option}`YAML` options are used, this is set automatically.

            If this is set, {option}`file`, {option}`YAML` or {option}`env` will not have any effect.
          '';
        };
        file = mkOption {
          default = (
            if config.YAML == null then
              null
            else
              pkgs.writers.writeYAML "docker-compose.yml" config.YAML
          );
          defaultText = "A docker-compose.yml generated from {option}`YAML`.";
          type = nullOr path;
          description = "The path to a docker-compose.yml. If this is set {option}`YAML` won't have an effect.";
        };
        YAML = mkOption {
          default = null;
          apply = yml: if yml == null then null else { version = "3"; } // yml;
          type = nullOr attrs;
          description = "An attrset representing a docker-compose.yml. The version `version` attribute is set to 3 by default.";
        };
        env = mkOption {
          default = null;
          type = nullOr attrs;
          description = "An attrset representin a docker-compose `.env` file.";
        };

        override = mkOption {
          default = null;
          apply = yml: if yml == null then null else { version = "3"; } // yml;
          type = nullOr attrs;
          description = "An attrset representing a docker-compose.override.yml. The version `version` attribute is set to 3 by default.";
        };

        stateDirectory = {
          enable = mkEnableOption "a systemd service state directory for this service";

          name = mkOption {
            default = name;
            defaultText = "The service's `name`";
            description = "The name of the state directory";
          };
        };

        wrapperScript = mkOption {
          internal = true;
          default = pkgs.writeShellScriptBin "docker-compose-${name}" (runConfig config ''"$@"'');
        };
      };
    }));
  };

  config = mkIf (this != { }) {
    virtualisation.docker.enable = true;

    systemd.services = mapAttrs' (name: value:
      nameValuePair "docker-compose-${name}" {
        serviceConfig = let
          run = runConfig value;
        in {
          # Stop services before in case they're running
          ExecStartPre = [
            (run "down")
            # Causes logspam on pull but shows more accurate activating info
            (run "create")
          ];
          ExecStart = run "up --quiet-pull --abort-on-container-exit";

          ExecStop = run "down";

          Restart = "on-failure";

          # It may take >15 minutes to pull large images
          TimeoutStartSec = 1000;

          StateDirectory = mkIf value.stateDirectory.enable value.stateDirectory.name;
        };
        path = [ pkgs.docker ];

        requires = [ "docker.service" ];
        wantedBy = [ "multi-user.target" ];
      }
    ) this;

    environment.systemPackages = mapAttrsToList (name: value: value.wrapperScript) this;
  };
}
