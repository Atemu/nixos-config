{ type ? "system", meta ? import ./meta.nix, asConfig ? false, withPackages ? true, ... }:

let
  configuration = {
    # Nixpkgs' module system can pass attrsets with config, lib etc. to lambdas
    # in `imports`. We can't do that ourselves in here because we don't have
    # access to them and I don't want to duplicate the implementation
    imports = [
      # This passes meta to common.nix which returns a lambda, the configuration.
      (import ./common.nix (meta // { inherit withPackages; }))
    ];
  };
in

if asConfig then configuration else (import <nixpkgs/nixos> { inherit configuration; })."${type}"
