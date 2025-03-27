{
  lib,
  config,
  ...
}:

let
  mapping = {
    THESEUS = {
      to = "SOTERIA";
      method = "borg";
      keys = {
        public = lib.readFile ./THESEUS.pub;
        private = "/var/lib/borg/THESEUS"; # TODO secret
      };
      user = "borg-THESEUS"; # TODO submodule
    };
  };
  this = config.custom.replication;
  host = this.mapping.${config.networking.hostName} or null;
  methods = lib.genAttrs [ "borg" ] lib.id;
  # The replications served by this host
  served = mapping |> lib.filterAttrs (n: v: v.to == config.networking.hostName);
in
{
  options.custom.replication = {
    enable = lib.mkEnableOption "replication for this host";
    mapping = lib.mkOption {
      default = mapping;
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
            host.to
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
