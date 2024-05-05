args@{
  nixpkgsPath ? <nixpkgs>,
  ...
}:

# HACK allow usage with both nixos-rebuild and nix-build
#
# NixOS calls this function with a certain set of arguments by default,
# including specialArgs which is pretty uniquely exclusive to NixOS modules.
# This allows us to differentiate what we're being called from; a module or
# nix-instantiate/nix-build.
if args ? specialArgs then {
  imports = [
    ./current-config.nix
  ];
}
else let
  configs = import ./configs;
  nixosFor = configuration: import (nixpkgsPath + /nixos) {
    inherit configuration;
  };
  nixosVmWithoutPackages = configuration: (nixosFor ({ pkgs, ... }: {
    imports = [
      configuration
    ];
    custom.packages.enable = pkgs.lib.mkForce false;
  })).vm;

  # Makes an attrset of all my nixos configurations.
  # Try `nix-build -A TAB TAB`. Pretty neat, huh?
in builtins.mapAttrs
  (_: config: nixosFor config // {
    vmWithoutPackages = nixosVmWithoutPackages config;
    vmWithPackages = (nixosFor config).vm;
  }) configs
