{
  config,
  lib,
  pkgs,
  ...
}:

let
  this = config.custom.borg;

  # TODO
  name = "Test";

  snapshotDir = "/System/Volumes/Snapshots/Temp";
in

{
  options.custom.replication.borg = {
    enable = lib.mkEnableOption "my custom borg setup";
    # TODO multiple
    subvol = lib.mkOption {
      description = ''
        The path of the subvolume to replicate.
      '';
      default = "/System/Volumes/${name}";
    };
    path = lib.mkOption {
      description = ''
        The path under the subvolume to replicate
      '';
      default = "";
      apply = lib.removePrefix "/";
    };
    target = {
      repo = lib.mkOption {
        description = ''
          The Borg repo to replicated to.
        '';
        type = lib.types.str;
      };
    };
  };

  config = lib.mkIf this.enable {
    services.borgbackup.jobs.${name} = {
      paths = [ "." ];
      preHook = ''
        tmpsnapshot="${snapshotDir}/${name}"

        if [ -e $tmpsnapshot ]; then
          # The previous run must have been interrupted; delete and try again
          ${lib.getExe' pkgs.btrfs-progs "btrfs"} subvolume delete $tmpsnapshot
        fi

        ${lib.getExe' pkgs.btrfs-progs "btrfs"} subvolume snapshot -r ${this.subvol} $tmpsnapshot

        pushd "$tmpsnapshot/${this.path}"
      '';

      inherit (this.target) repo;

      exclude = [
        "immich"
        "docker"
        "containers"
        "borg"
      ];

      readWritePaths = [ snapshotDir ];

      encryption.mode = "none";
    };
  };
}
