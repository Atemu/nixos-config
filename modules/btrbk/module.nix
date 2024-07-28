{ config, lib, ... }:

let
  this = config.custom.btrbk;
in

{
  options.custom.btrbk = {
    enable = lib.mkEnableOption "automatic snapshots using btrbk";

    volume = lib.mkOption {
      description = "Btrbk volumes declarations";
      default = { };
    };
  };

  config.services.btrbk.instances."btrbk" = lib.mkIf this.enable {
    onCalendar = "*:0/15"; # Every 15min
    settings = {
      timestamp_format = "long-iso"; # Most sensible of the bunch
      snapshot_preserve = "12h 7d 3w 1m 0y"; # Don't want to keep too many snapshots
      # snapshot_preserve_min = "3h 3d 1w 1m 0y";
      snapshot_preserve_min = "1h"; # Preserve all my <1h snapshots

      preserve_day_of_week = "monday"; # A week starts on monday.

      snapshot_create = "onchange"; # Only create snapshots if the subvol actually changed
      snapshot_dir = "Snapshots";

      inherit (this) volume;
    };
  };
}
