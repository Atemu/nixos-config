args@{
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
  nixpkgsConfig = import ./nixpkgs-config.nix;
  selectNixfile = import ./select-nixfile.nix;
  nixosFor = hostname: configuration: let
    nixpkgs =
      if args ? nixpkgsPath then
        args.nixpkgsPath
      else
        selectNixfile nixpkgsConfig.${hostname} or nixpkgsConfig.default;
  in import nixpkgs {
    inherit configuration;
  };
  nixosVmWithoutPackages = hostname: configuration: (nixosFor hostname ({ pkgs, ... }: {
    imports = [
      configuration
    ];
    custom.packages.enable = pkgs.lib.mkForce false;
  })).vm;

  # Makes an attrset of all my nixos configurations.
  # Try `nix-build -A TAB TAB`. Pretty neat, huh?
in builtins.mapAttrs
  (name: config: nixosFor name config // {
    vmWithoutPackages = nixosVmWithoutPackages name config;
    vmWithPackages = (nixosFor name config).vm;
  }) configs
