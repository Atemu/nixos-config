{ config, lib, ... }:

let
  this = config.custom.borg;
in

{
  options.custom.borg = {
    enable = lib.mkEnableOption "my custom borg setup";
    # TODO multiple
    path = lib.mkOption {
      description = ''
        The path to back up relative to.
      '';
    };
  };

  config = lib.mkIf this.enable {
    services.borgbackup.jobs.test = {
      paths = [ "." ];
      preHook = ''
        pushd ${this.path}
      '';

      repo = "/var/lib/borg/";

      exclude = [
        "immich"
        "docker"
        "containers"
        "borg"
      ];

      encryption.mode = "none";
    };
  };
}
