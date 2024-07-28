{ lib, config, ... }:

let
  this = config.custom.vm;
in

{
  options.custom.vm.enable = lib.mkEnableOption "sensible defaults for use in a VM for testing";

  config = lib.mkIf this.enable {
    users.users.atemu.initialHashedPassword = "";
    users.users.root.initialHashedPassword = "";

    security.sudo.wheelNeedsPassword = lib.mkForce false;

    services.getty.autologinUser = "atemu";
  };
}
