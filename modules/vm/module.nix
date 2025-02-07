{
  lib,
  config,
  options,
  ...
}:

let
  this = config.custom.vm;
in

{
  options.custom.vm.enable = lib.mkEnableOption "sensible defaults for use in a VM for testing";

  config = lib.mkIf this.enable (
    {
      users.users.atemu.initialHashedPassword = "";
      users.users.root.initialHashedPassword = "";

      security.sudo.wheelNeedsPassword = lib.mkForce false;

      services.getty.autologinUser = "atemu";
    }
    // lib.optionalAttrs (options.virtualisation ? memorySize) {
      # These options don't exist unless you are in the VM profile
      virtualisation.diskSize = 10 * 1024; # Create 10GiB disk by default
      virtualisation.memorySize = 4 * 1024; # 4GiB memory rather than the meager 1GiB
    }
  );
}
