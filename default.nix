args@{ ... }:

# HACK allow usage with both nixos-rebuild and nix-build
#
# NixOS calls this function with a certain set of arguments by default but
# calling nix-build only does that when supplied with --arg. This allows us to
# differentiate where we're called from.
#
# Yes, this a hack. No there's no better way, I tried.
if args != { } then {
  imports = [
    ./current-config.nix
  ];
}
else let
  pkgs = import <nixpkgs> { };
  configs = import ./configs { inherit (pkgs) lib; };
  nixosFor = configuration: import <nixpkgs/nixos> {
    inherit configuration;
  };
  nixosVmWithoutPackages = configuration: (nixosFor {
    imports = [
      configuration
    ];
    custom.packages.enable = pkgs.lib.mkForce false;
  }).vm;

  # Makes an attrset of all my nixos configurations.
  # Try `nix-build -A TAB TAB`. Pretty neat, huh?
in builtins.mapAttrs
  (_: config: nixosFor config // {
    vmWithoutPackages = nixosVmWithoutPackages config;
    vmWithPackages = (nixosFor config).vm;
  }) configs
