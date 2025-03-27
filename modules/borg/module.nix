{
  config,
  lib,
  pkgs,
  ...
}:

let
  this = config.custom.replication.borg;

  snapshotDir = "/System/Volumes/Snapshots/Temp";
in

{
  options.custom.replication.borg = {
    enable = lib.mkEnableOption "my custom borg setup";
    target = {
      repo = lib.mkOption {
        description = ''
          The Borg repo to replicated to.
        '';
        type = lib.types.str;
      };
    };
    key = lib.mkOption {
      description = ''
        The SSH keyfile to use to connect to the chosen replication remote
      '';
    };
  };

  config = lib.mkIf this.enable {
    services.borgbackup.jobs =
      config.custom.replication.replications
      |> lib.mapAttrs' (
        name: replication:
        lib.nameValuePair name {
          paths = [ "." ];
          preHook = ''
            tmpsnapshot="${snapshotDir}/${name}"

            if [ -e $tmpsnapshot ]; then
              # The previous run must have been interrupted; delete and try again
              ${lib.getExe' pkgs.btrfs-progs "btrfs"} subvolume delete $tmpsnapshot
            fi

            ${lib.getExe' pkgs.btrfs-progs "btrfs"} subvolume snapshot -r ${replication.subvol} $tmpsnapshot

            pushd "$tmpsnapshot/${replication.path}"
          '';

          repo = "${this.target.repo}/${name}";

          environment.BORG_RSH = "ssh -i ${this.key}";

          exclude = [
            "immich"
            "docker"
            "containers"
            "borg"
          ];

          readWritePaths = [ snapshotDir ];

          encryption.mode = "none";
        }
      );
  };
}
