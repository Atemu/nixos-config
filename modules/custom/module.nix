{ lib, config, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkOption types mkIf;
  this = config.custom;
in

{
  options.custom = {
    enable = mkEnableOption "my custom modules";

    # TODO move to emacs module
    emacs = mkOption {
      description = "Emacs package to use.";
      default = pkgs.emacs29;
      example = pkgs.emacs-nox;
      type = types.package;
    };
  };

  config = mkIf this.enable {
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
      (treesit-grammars.with-grammars (grammars: with grammars; [
        tree-sitter-nix
      ]))
    ]);
  };
}
