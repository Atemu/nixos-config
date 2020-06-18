{ config, pkgs, ... }:

{
  imports = [
    ./desktop.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_5_6;

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.steam-hardware.enable = true;

  system.stateVersion = "20.09";
}
