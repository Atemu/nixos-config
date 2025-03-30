{ lib, ... }:

{
  imports =
    (builtins.readDir ./modules)
    |> lib.mapAttrs (n: _: ./modules + "/${n}/module.nix")
    |> lib.filterAttrs (_: lib.pathExists)
    |> lib.mapAttrsToList (_: lib.id);
}
