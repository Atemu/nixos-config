{ config, lib, ... }:

let
  this = config.custom.bootloader;
in

{
  options.custom.bootloader = {
    enable = lib.mkEnableOption "my bootloader abstraction";
    choice = lib.mkOption {
      default = "systemd-boot";
      type = lib.types.enum [ "systemd-boot" ];
      description = "The bootloader to use. Currently, only systemd-boot is supported";
    };
  };

  config = lib.mkIf (this.enable && this.choice == "systemd-boot") {
    boot.loader.grub.enable = false;
    boot.loader.systemd-boot.enable = true;
    boot.loader.systemd-boot.consoleMode = "auto";
    boot.loader.efi.canTouchEfiVariables = true;

    boot.loader.timeout = 1;
  };
}
