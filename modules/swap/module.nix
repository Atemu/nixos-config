{ config, lib, ... }:

let
  this = config.custom.swap;
in

{
  options.custom.swap.devices = lib.mkOption {
    description = "Configure disk-backed swap devices";
    type = lib.types.attrsOf (lib.types.submodule ({ ... }: {
      options = {
        enable = lib.mkEnableOption "this device";
        partUUID = lib.mkOption {
          description = "The partUUID of the device";
          type = lib.types.str;
        };
        random = lib.mkEnableOption "random encryption" // lib.mkOption { default = true; };
      };
    }));
    default = { };
  };

  config = let
    enabledDevices = lib.filterAttrs (n: v: v.enable) this.devices;
  in lib.mkIf (enabledDevices != { }) {
    swapDevices = lib.mapAttrsToList (_: device: {
      device = "/dev/disk/by-partuuid/${device.partUUID}";
      randomEncryption = {
        enable = device.random;
        sectorSize = 4096; # Pages are 4k anyways
        # Does not expose information other than how much swap I'm using which I
        # don't care about.
        allowDiscards = true;
      };
    }) enabledDevices;
  };
}
