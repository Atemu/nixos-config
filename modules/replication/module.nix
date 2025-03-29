{
  lib,
  config,
  ...
}:

let
  this = config.custom.replication;

  # The top-level path under which replications are stored
  replicationPaths = {
    SOTERIA = "/Volumes/Data/Replication";
  };

  # The methods for replication. Currently, only borg is supported.
  methods = lib.genAttrs [ "borg" ] lib.id;

  host = this.mapping.${config.networking.hostName} or null;

  # The replications served by this host
  served = this.mapping |> lib.filterAttrs (n: v: v.to == config.networking.hostName);
in
{
  options.custom.replication = {
    enable = lib.mkEnableOption "replication for this host";

    mapping = lib.mkOption {
      type =
        lib.types.attrsOf
        <| lib.types.submodule (
          { name, ... }:
          {
            options = {
              to = lib.mkOption { default = "SOTERIA"; };
              method = lib.mkOption {
                type = lib.types.enum <| lib.attrValues methods;
                default = "borg";
              };
              user = lib.mkOption {
                type = lib.types.str;
                default = "${name}-replication";
              };
              key = lib.mkOption {
                type = lib.types.str;
                description = ''
                  The the public part of the replication key of this host.
                '';
              };
            };
          }
        );
      default = { };
    };

    replications = lib.mkOption {
      description = ''
        The volumes to replicate. They will be populated under the host's target directory.

        These are *not* part of the mapping and can be set by the host's modules arbitrarily.
      '';
      type =
        lib.types.attrsOf
        <| lib.types.submodule (
          { name, ... }:
          {
            options = {
              enable = lib.mkEnableOption "this volume for replication" // lib.mkOption { default = true; };

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
              exclude = lib.mkOption {
                type = with lib.types; listOf str;
                description = ''
                  Paths to exclude from replication.

                  This only has an effect when the chosen replication method supports excludes and the interpretation also depends on the chosen replication method.
                '';
                default = [ ];
              };
            };
          }
        );
      default = { };
    };
  };

  config = lib.mkIf this.enable {
    custom.replication.borg = lib.mkIf (host != null && host.method == methods.borg) {
      enable = true;
      target.repo =
        let
          domain = config.lib.custom.concatDomain [
            (lib.toLower host.to)
            config.custom.acme.primaryDomain
          ];
          replicationPath = replicationPaths.${host.to};
        in
        "ssh://${host.user}@${domain}${replicationPath}/${config.networking.hostName}/Borg";
      key = config.custom.secrets.replication.path;
    };

    custom.secrets.replication = lib.mkIf (host != null) { };

    services.borgbackup.repos =
      served
      |> lib.filterAttrs (n: v: v.method == methods.borg)
      |> lib.mapAttrs (
        name: host: {
          path = "${replicationPaths.${config.networking.hostName}}/${name}/Borg/";
          inherit (host) user;
          authorizedKeys = [ host.key ];
          allowSubRepos = true; # Each host can have multiple replicated volumes
        }
      );
  };
}
