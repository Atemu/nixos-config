{ lib, config, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkOption types mkIf substring mkDefault;
  this = config.custom;
in

{
  options.custom = {
    enable = mkEnableOption "my custom modules";

    hostName = mkOption {
      description = "The name of the host whose config to build.";
      default = "HEPHAISTOS";
      example = "PLATON";
      type = types.str;
    };

    emacs = mkOption {
      description = "Emacs package to use.";
      # TODO Use { withGTK3 = false; } again
      default = pkgs.emacs29;
      example = pkgs.emacs-nox;
      type = types.package;
      # implemented in packages.nix and desktop.nix
    };
  };

  config = mkIf this.enable {
    networking.hostName = this.hostName;

    # The hostId is set to the first 8 chars of the sha256 of the hostName
    networking.hostId = substring 0 8 (builtins.hashString "sha256" this.hostName);

    # Enable default-on custom modules
    custom.lib.enable = true;
    custom.packages.enable = true;
    custom.overlays.enable = true;
    custom.bootloader.enable = true;

    virtualisation.vmVariant = {
      custom.vm.enable = true;
    };
  };
}
