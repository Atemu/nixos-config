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

  # The client config for this. Null if there is no client config for this host.
  client = this.mapping.${config.networking.hostName} or null;

  # The replications served by this host
  served = this.mapping |> lib.filterAttrs (n: v: v.to == config.networking.hostName);
in
{
  options.custom.replication = {
    enable = lib.mkEnableOption ''
      replication for this host.

      See the {option}`mapping` config for what this does on this particular host
    '';

    mapping = lib.mkOption {
      type =
        lib.types.attrsOf
        <| lib.types.submodule (
          { name, ... }:
          {
            options = {
              to = lib.mkOption {
                type = lib.types.str;
                description = "Which host to replicate to.";
                default = "SOTERIA";
              };
              method = lib.mkOption {
                type = lib.types.enum <| lib.attrValues methods;
                description = "The method to use to replicate to the given host.";
                default = "borg";
              };
              user = lib.mkOption {
                type = lib.types.str;
                description = "The name of the UNIX user to be used on the given host.";
                default = "${name}-replication";
              };
              key = lib.mkOption {
                type = lib.types.str;
                description = "The the public part of the replication key of the client.";
              };
            };
          }
        );
      default = { };
    };

    replications = lib.mkOption {
      description = ''
        The volumes to replicate.
        These will be populated under the replication host's target directory for this client.

        These options are *not* part of the {option}`mapping` and can be set by the host's modules arbitrarily.
      '';
      type =
        lib.types.attrsOf
        <| lib.types.submodule (
          { name, ... }:
          {
            options = {
              enable = lib.mkEnableOption "this volume for replication" // lib.mkOption { default = true; };

              subvol = lib.mkOption {
                type = lib.types.path;
                description = ''
                  The path of the btrfs subvolume to replicate.
                '';
                default = "/System/Volumes/${name}";
              };
              path = lib.mkOption {
                description = ''
                  The path under the btrfs subvolume to replicate.

                  This only has an effect if the chosen replication method supports sub-paths
                '';
                default = "";
                apply = lib.removePrefix "/";
              };
              exclude = lib.mkOption {
                type = with lib.types; listOf str;
                description = ''
                  Paths to exclude from replication.

                  This only has an effect if the chosen replication method supports excludes.
                  The interpretation also depends on the chosen replication method.
                '';
                default = [ ];
              };
            };
          }
        );
      default = { };
    };
  };

  imports = [
    ./borg.nix # The borg implementation of replication
  ];

  config = lib.mkIf this.enable {
    custom.replication.borg = lib.mkIf (client != null && client.method == methods.borg) {
      enable = true;
      target.repo =
        let
          domain = config.lib.custom.concatDomain [
            (lib.toLower client.to)
            config.custom.acme.primaryDomain
          ];
          replicationPath = replicationPaths.${client.to};
        in
        "ssh://${client.user}@${domain}${replicationPath}/${config.networking.hostName}/Borg";
      key = config.custom.secrets.replication.path;
    };

    custom.secrets.replication = lib.mkIf (client != null) { };

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
