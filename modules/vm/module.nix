{ lib, config, ... }:

let
  cfg = config.custom.vm;
  inherit (lib) mkEnableOption mkMerge mkIf;
in

{
  options.custom.vm.enable = mkEnableOption "sensible defaults for use in a VM for testing";

  config = mkIf cfg.enable {
    users.users.atemu.initialHashedPassword = "";
    users.users.root.initialHashedPassword = "";

    security.sudo.wheelNeedsPassword = lib.mkForce false;

    services.getty.autologinUser = "atemu";
  };
}
