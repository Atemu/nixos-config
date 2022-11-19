{ lib, config, ... }:

let
  cfg = config.custom.vm;
  hasVmVariant = config.virtualisation ? vmVariant;
  vmConfig = {
    users.users.atemu.initialHashedPassword = "";
    users.users.root.initialHashedPassword = "";

    security.sudo.wheelNeedsPassword = lib.mkForce false;

    services.getty.autologinUser = "atemu";
  };
  inherit (lib) mkOption mkMerge mkIf;
in

{
  options.custom.vm.enable = mkOption {
    description = "Sensible config options for use in a VM";
    default = !hasVmVariant && builtins.hasAttr "vm" config.system.build;
  };

  # Ugly because the module system doesn't support if then else.
  config = mkMerge [
    {
      virtualisation.vmVariant = mkIf hasVmVariant vmConfig;

      # The mkIf is *false*, but the option checker doesn't care.
      # Get your shit together module system. I should not have to do this.
      _module.check = false; # Ew.
    }

    (mkIf cfg.enable vmConfig)
  ];
}
