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
else builtins.mapAttrs
  # Makes an attrset of all my nixos configurations.
  # Try `nix-build -A TAB TAB`. Pretty neat, huh?
  (n: v: import <nixpkgs/nixos> { configuration = v; })
  (import ./configs { lib = (import <nixpkgs> { }).lib; })

