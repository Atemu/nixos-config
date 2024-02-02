{ config, lib, ... }:

let
  this = config.custom.bootloader;
  inherit (lib) mkEnableOption mkOption types mkIf;
in

{
  options.custom.bootloader = {
    enable = mkEnableOption "my bootloader abstraction";
    choice = mkOption {
      default = "systemd-boot";
      type = types.enum [ "systemd-boot" ];
      description = "The bootloader to use. Currently, only systemd-boot is supported";
    };
  };

  config = mkIf (this.enable && this.choice == "systemd-boot") {
    boot.loader.grub.enable = false;
    boot.loader.systemd-boot.enable = true;
    boot.loader.systemd-boot.consoleMode = "auto";
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
