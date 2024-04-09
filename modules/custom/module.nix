{ lib, config, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkOption types mkIf substring mkDefault;
  this = config.custom;
in

{
  options.custom = {
    enable = mkEnableOption "my custom modules";

    emacs = mkOption {
      description = "Emacs package to use.";
      default = pkgs.emacs29;
      example = pkgs.emacs-nox;
      type = types.package;
    };
  };

  config = mkIf this.enable {
    # The hostId is set to the first 8 chars of the sha256 of the hostName
    networking.hostId = substring 0 8 (builtins.hashString "sha256" config.networking.hostName);

    # Enable default-on custom modules
    custom.lib.enable = true;
    custom.packages.enable = true;
    custom.overlays.enable = true;
    custom.bootloader.enable = true;

    virtualisation.vmVariant = {
      custom.vm.enable = true;
    };

    services.emacs.package = (config.custom.emacs.override {
      noGui = !config.custom.desktop.enable;
    }).pkgs.withPackages (ep: with ep; [
      # Require native code
      vterm
      pdf-tools
    ]);
  };
}
