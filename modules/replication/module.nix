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
  methods = lib.genAttrs lib.id [ "borg" ];
in
{
  options.custom.replication = {
    enable = lib.mkEnableOption "replication for this host";
    mapping = lib.mkOption {
      default = mapping;
      readOnly = true;
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
  };
}
