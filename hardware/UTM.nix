{ lib, ... }:

{
  nixpkgs.localSystem = lib.systems.examples.aarch64-multiplatform;
}
