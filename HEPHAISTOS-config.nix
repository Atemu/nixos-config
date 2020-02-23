{ config, pkgs, ... }:

{
  imports = [
    ./desktop.nix
  ];

  system.stateVersion = "20.09";
}
