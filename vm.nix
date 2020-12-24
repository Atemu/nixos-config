{ lib, config, ... }:

with lib;

# Only applied when this is built via build-vm
mkIf (builtins.hasAttr "vm" config.system.build) {
  users.users.atemu.initialHashedPassword = "";
  users.users.root.initialHashedPassword = "";

  security.sudo.wheelNeedsPassword = mkForce false;

  services.mingetty.autologinUser = "atemu";

  custom.withPackages = false;
}
