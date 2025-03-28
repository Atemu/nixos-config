{
  lib,
  config,
  pkgs,
  ...
}:

let
  this = config.custom;
in

{
  options.custom = {
    enable = lib.mkEnableOption "my custom modules";

    # TODO move to emacs module
    emacs = lib.mkOption {
      description = "Emacs package to use.";
      default = pkgs.emacs;
      example = pkgs.emacs-nox;
      type = lib.types.package;
    };

    # TODO should be enabled by default once all hosts are migrated
    secretPassword = lib.mkEnableOption "password provided by secrets module";
  };

  config = lib.mkIf this.enable {
    # Enable default-on custom modules
    custom.lib.enable = true;
    custom.packages.enable = true;
    custom.overlays.enable = true;
    custom.bootloader.enable = true;

    virtualisation.vmVariant = {
      custom.vm.enable = true;
    };

    custom.secrets =
      lib.mkIf this.secretPassword
      <| lib.listToAttrs
      <| map (user: lib.nameValuePair "${user}/hashedPassword" { }) [
        "atemu"
        "root"
      ];
    users.users =
      lib.mkIf this.secretPassword
      <| lib.genAttrs [ "atemu" "root" ] (user: {
        hashedPasswordFile = config.custom.secrets."${user}/hashedPassword".path;
      });
    users.mutableUsers = lib.mkIf this.secretPassword false;

    services.emacs.package =
      (config.custom.emacs.override {
        noGui = !config.custom.desktop.enable;
      }).pkgs.withPackages
        (
          ep: with ep; [
            # Require native code
            vterm
            pdf-tools
            (treesit-grammars.with-grammars (
              grammars: with grammars; [
                tree-sitter-nix
              ]
            ))
          ]
        );
  };
}
