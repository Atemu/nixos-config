{ config, lib, pkgs, ... }:

let
  this = config.custom.docker-compose;

  inherit (lib) mkOption mkIf mapAttrs' nameValuePair;
  inherit (lib.types) attrsOf submodule path;
in

{
  options.custom.docker-compose = mkOption {
    default = { };
    type = attrsOf (submodule ({ name, ... }: {
      options = {
        file = mkOption {
          default = throw "You must provide a file for the ${name} docker-compose service";
          type = path;
        };
      };
    }));
  };

  config = mkIf (this != { }) {
    virtualisation.docker.enable = true;

    systemd.services = mapAttrs' (name: value:
      nameValuePair "docker-compose-${name}" {
        serviceConfig = let
          run = command: "${lib.getExe pkgs.docker} compose -f ${value.file} ${command}";
        in {
          # Stop services before in case they're running
          ExecStartPre = run "down";
          ExecStart = run "up";
          ExecStop = run "down";
        };
        path = [ pkgs.docker ];

        requires = [ "docker.socket" ];
        wantedBy = [ "multi-user.target" ];
      }
    ) this;
  };
}
