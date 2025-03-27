{
  lib,
  config,
  ...
}:

let
  this = config.custom.replication;

  hostMapping = {
    THESEUS = {
      keys = {
        public = lib.readFile ./THESEUS.pub;
        private = "/var/lib/borg/THESEUS"; # TODO secret
      };
    };
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
              keys = {
                public = lib.mkOption {
                  type = lib.types.str;
                  description = ''
                    Path to the public key file for the borg key of this host.
                  '';
                };
                private = lib.mkOption {
                  type = lib.types.str;
                  description = ''
                    Path to the public key file for the borg key of this host.

                    This must only be readable by the {option}`user`.
                  '';
                };
              };
            };
          }
        );
      default = hostMapping;
      readOnly = true;
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
        in
        # TODO path under domain static
        "ssh://${host.user}@${domain}/Volumes/Data/Replication/${config.networking.hostName}/Borg";
      key = host.keys.private;
    };

    services.borgbackup.repos =
      served
      |> lib.filterAttrs (n: v: v.method == methods.borg)
      |> lib.mapAttrs (
        n: v: {
          path = "/Volumes/Data/Replication/${n}/Borg/"; # TODO replication path as some sort of static mapping?
          inherit (v) user;
          authorizedKeys = [ v.keys.public ];
          allowSubRepos = true; # Each host can have multiple replicated volumes
        }
      );
  };
}
