{
  config,
  lib,
  pkgs,
  ...
}:

let
  this = config.custom.borg;

  # TODO
  name = "Root";
in

{
  options.custom.borg = {
    enable = lib.mkEnableOption "my custom borg setup";
    # TODO multiple
    path = lib.mkOption {
      description = ''
        The path to back up relative to.
      '';
      apply = lib.removePrefix "/";
    };
  };

  config = lib.mkIf this.enable {
    services.borgbackup.jobs.${name} = {
      paths = [ "." ];
      preHook =
        let
          regex = "^.* snapshot_subvolume='(/.*?/Root\..*?)' .*$";
          # Parses the `btrbk list --format=raw` output and returns the snapshot paths in order.
          filterSnapshots = lib.concatStringsSep " " [
            (lib.getExe pkgs.ripgrep)
            (lib.escapeShellArgs [
              regex
              # Print the capture
              "--replace"
              "$1"
            ])
          ];
        in
        ''
          snapshot="$(${lib.getExe pkgs.btrbk} list --format=raw | ${filterSnapshots} | tail -n 1)"
          pushd "$snapshot/${this.path}"
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
