{ config, pkgs, ... }:

{
  imports = [
    ./desktop.nix
  ];

  services.xserver.videoDrivers = [ "nvidia" ];

  system.stateVersion = "20.09";
}
