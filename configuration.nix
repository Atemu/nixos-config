{ config, pkgs, ... }:

let
  # meta.nix provides hostName and productName
  meta = import ./meta.nix;
in

{
  imports = [
    # TODO: Find cleaner way to specify these
    # Include host-specific configuration
    (
      let
        hostNix = (./. + "/${meta.hostName}.nix");
      in
      if (builtins.pathExists hostNix)
        then hostNix
      else ./genericHost.nix
    )

    # Include hardware-specific configuration
    (
      let
        productNix = (./. + "/${meta.productName}.nix");
      in
      if (builtins.pathExists productNix)
        then productNix
      else ./hardware-configuration.nix
    )
  ];

  # List of packages installed in system profile.
  # If the host config enables X, X packages are also imported
  environment.systemPackages = with import ./systemPackages.nix pkgs;
                               common ++ (if config.services.xserver.enable then x else noX);

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.atemu = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
}
