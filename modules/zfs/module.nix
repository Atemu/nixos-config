{ lib, config, ... }:

with lib;

let
  this = config.custom.zfs;
in

{
  options.custom.zfs = {
    enable = mkEnableOption "my preferred ZFS settings";
  };

  config = mkIf this.enable {
    boot.supportedFilesystems = [ "zfs" ];
    boot.zfs.forceImportAll = false;
    boot.zfs.forceImportRoot = false;

    services.zfs.trim.enable = true;
    services.zfs.trim.interval = "weekly"; #default

    services.zfs.autoSnapshot.enable = true;

    virtualisation.docker.storageDriver = "zfs";
  };
}
