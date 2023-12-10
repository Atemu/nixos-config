{ lib, ... }:

{
  imports = lib.mapAttrsToList (n: v: ./modules + "/${n}/module.nix") (builtins.readDir ./modules);
}
