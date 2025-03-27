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
        public = "";
        private = ""; # TODO secret
      };
    };
  };
  this = config.custom.replication;
  host = this.mapping.${config.networking.hostName};
  methods = lib.genAttrs [ "borg" ] lib.id;
  # The replications served by this host
  served =
    mapping
    |> lib.filterAttrs (n: v: v.to == config.networking.hostName)
    |> lib.mapAttrs (n: v: v.method);
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
      type = with lib.types; attrsOf str; # TODO submodule?
      default = { };
    };
  };

  config = lib.mkIf this.enable {
    # TODO assert host exists in mapping
    # TODO multiple hosts
    custom.replication.borg = lib.mkIf (host.method == methods.borg) {
      enable = true;
      host = host.to;
      key = host.keys.private;
    };

    services.borgbackup.repos =
      served
      |> lib.filterAttrs (n: v: v.method == methods.borg)
      |> lib.mapAttrs (
        n: v: {
          path = "/Volumes/Data/Replication/${n}/Borg/"; # TODO replication path as some sort of static mapping?
          user = "borg-${n}";
          authorizedKeys = [ v.keys.public ];
          allowSubRepos = true; # Each host can have multiple replicated volumes
        }
      );
  };
}
