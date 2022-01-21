{ lib, config, ... }:

let
  hasVmVariant = config.virtualisation ? vmVariant;
  vmConfig = {
    users.users.atemu.initialHashedPassword = "";
    users.users.root.initialHashedPassword = "";

    security.sudo.wheelNeedsPassword = lib.mkForce false;

    services.getty.autologinUser = "atemu";
  };
in

# Ugly because the module system doesn't support if then else.
lib.mkMerge [
  {
    virtualisation.vmVariant = lib.mkIf hasVmVariant vmConfig;

    # The mkIf is *false*, but the option checker doesn't care.
    # Get your shit together module system. I should not have to do this.
    _module.check = false; # Ew.
  }
  (lib.mkIf (!hasVmVariant && builtins.hasAttr "vm" config.system.build) vmConfig)
]
