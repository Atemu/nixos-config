{ config, ... }:

with config.lib.custom;

{
  boot.loader.grub.devices = [ "nodev" ];
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.efiSupport = true;

  custom.fs.enable = true;
  custom.fs.boot = mkUuid "21F5-7652";
  custom.fs.btrfs.enable = true;
  custom.fs.btrfs.device = mkUuid "53a12e2b-fdd8-4b83-ba37-369baa7ec1ab";
  custom.fs.btrfs.newLayout = true;

  # systemd.timers.btrbk-btrbk.timerConfig.AccuracySec = lib.mkForce "1s";
  services.btrbk.instances."btrbk" = {
    onCalendar = "*:0/15"; # Every 15min
    settings = {
      timestamp_format = "long-iso"; # Most sensible of the bunch
      snapshot_preserve = "12h 7d 3w 1m 0y"; # Don't want to keep too many snapshots
      # snapshot_preserve_min = "3h 3d 1w 1m 0y";
      snapshot_preserve_min = "1h"; # Preserve all my <1h snapshots

      preserve_day_of_week = "monday"; # A week starts on monday.

      snapshot_create = "onchange"; # Only create snapshots if the subvol actually changed
      snapshot_dir = "Snapshots";

      volume."/System/Volumes" = {
        subvolume."Users" = { };
      };
    };
  };
}
