{ config, lib, ... }:

let
  this = config.custom.borg;

  # TODO
  name = "test";
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
    services.borgbackup.jobs.${name} = {
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

    systemd.services."borgbackup-job-${name}" = {
      # Create btrbk snapshots before
      wants = [
        # TODO what's the name mapping here? Is there not one btrbk service per snapshot declaration?
        "btrbk-btrbk.service"
      ];
    };
  };
}
