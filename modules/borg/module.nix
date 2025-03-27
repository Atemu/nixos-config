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
  options.custom.borg = {
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
      host = lib.mkOption {
        description = ''
          The name of the host on which the Borg repo to be replicated to lies.
        '';
        default = "soteria";
        type = lib.types.str;
      };
      replicationDir = lib.mkOption {
        description = ''
          The path of the directory to which should be replicated
        '';
        default = "soteria";
        type = lib.types.str;
      };
      path = lib.mkOption {
        description = ''
          The path to the borg repo on the host
        '';
        default = "${this.target.replicationDir}";
        type = lib.types.str;
        internal = true;
      };
      repo = lib.mkOption {
        default =
          let
            domain = config.lib.custom.concatDomain [
              this.target.host
              config.custom.acme.primaryDomain
            ];
          in
          "ssh://${domain}/Volumes/Data/Replication/${config.networking.hostName}/${name}";
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

      repo = "/var/lib/borg/";

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
