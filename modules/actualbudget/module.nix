{ lib, config, ... }:

let
  this = config.custom.actualbudget;
in

{
  options.custom.actualbudget = {
    enable = lib.mkEnableOption "my custom actualbudget";

    port = lib.mkOption {
      default = 5006;
      type = lib.types.port;
    };
  };

  config = lib.mkIf this.enable {
    # Basically the simply upstream docker-compose.yml
    # https://github.com/actualbudget/actual-server/blob/master/docker-compose.yml
    custom.docker-compose.actualbudget.YAML = {
      services.actual_server = {
        image = "docker.io/actualbudget/actual-server:latest";
        ports = [ "${toString this.port}:5006" ];
        volumes = [ "actual-data:/data/" ];
      };

      volumes.actual-data.name = "actual-data";
    };

    custom.virtualHosts.actualbudget = {
      localPort = this.port;
    };
  };
}
