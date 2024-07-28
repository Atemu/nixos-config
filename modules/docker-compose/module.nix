{ config, lib, pkgs, ... }:

let
  this = config.custom.docker-compose;

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
  options.custom.docker-compose = lib.mkOption {
    default = { };
    type = lib.types.attrsOf (lib.types.submodule ({ name, config, ... }: {
      options = {
        directory = lib.mkOption {
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
          type = lib.types.path;
          description = ''
            A directory containing a docker-compose.yml.

            If the {option}`file` or {option}`YAML` options are used, this is set automatically.

            If this is set, {option}`file`, {option}`YAML` or {option}`env` will not have any effect.
          '';
        };
        file = lib.mkOption {
          default = (
            if config.YAML == null then
              null
            else
              pkgs.writers.writeYAML "docker-compose.yml" config.YAML
          );
          defaultText = "A docker-compose.yml generated from {option}`YAML`.";
          type = with lib.types; nullOr path;
          description = "The path to a docker-compose.yml. If this is set {option}`YAML` won't have an effect.";
        };
        YAML = lib.mkOption {
          default = null;
          apply = yml: if yml == null then null else { version = "3"; } // yml;
          type = with lib.types; nullOr attrs;
          description = "An attrset representing a docker-compose.yml. The version `version` attribute is set to 3 by default.";
        };
        env = lib.mkOption {
          default = null;
          type = with lib.types; nullOr attrs;
          description = "An attrset representing a docker-compose `.env` file.";
        };

        override = lib.mkOption {
          default = null;
          apply = yml: if yml == null then null else { version = "3"; } // yml;
          type = with lib.types; nullOr attrs;
          description = "An attrset representing a docker-compose.override.yml. The version `version` attribute is set to 3 by default.";
        };

        stateDirectory = {
          enable = lib.mkEnableOption "a systemd service state directory for this service";

          name = lib.mkOption {
            default = name;
            defaultText = "The service's `name`";
            description = "The name of the state directory";
          };
        };

        wrapperScript = lib.mkOption {
          internal = true;
          default = pkgs.writeShellScriptBin "docker-compose-${name}" (runConfig config ''"$@"'');
        };
      };
    }));
  };

  config = lib.mkIf (this != { }) {
    virtualisation.docker.enable = true;
    # Don't persist containers when docker daemon stops
    virtualisation.docker.liveRestore = false;

    systemd.services = lib.mapAttrs' (name: value:
      lib.nameValuePair "docker-compose-${name}" {
        serviceConfig = let
          run = runConfig value;
        in {
          # Stop services before in case they're running
          # TODO Remove containers too!
          ExecStartPre = [
            (run "down")
            (run "create ${with lib; optionalString (versionAtLeast trivial.release "24.05") "--quiet-pull"}")
          ];
          ExecStart = run "up --quiet-pull --abort-on-container-exit";

          ExecStop = run "down";

          Restart = "on-failure";

          # It may take >15 minutes to pull large images
          TimeoutStartSec = 1000;

          StateDirectory = lib.mkIf value.stateDirectory.enable value.stateDirectory.name;
        };
        path = [ pkgs.docker ];

        requires = [ "docker.service" ];
        after = [ "docker.service" ];
        wantedBy = [ "multi-user.target" ];
      }
    ) this;

    environment.systemPackages = lib.mapAttrsToList (_: value: value.wrapperScript) this;
  };
}
