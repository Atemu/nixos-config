{ config, lib, ... }:

let
  bootloader = config.custom.bootloader;
  inherit (lib) mkOption types mkIf;
in

{
  options.custom.bootloader = mkOption {
    default = "systemd-boot";
    type = types.enum [ "systemd-boot" ];
    description = "The bootloader to use. Currently, only systemd-boot is supported";
  };

  config = mkIf (bootloader == "systemd-boot") {
    boot.loader.grub.enable = false;
    boot.loader.systemd-boot.enable = true;
    boot.loader.systemd-boot.consoleMode = "auto";
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
