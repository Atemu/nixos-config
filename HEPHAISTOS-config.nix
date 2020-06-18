{ config, pkgs, ... }:

{
  imports = [
    ./desktop.nix
  ];

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.steam-hardware.enable = true;

  system.stateVersion = "20.09";
}
