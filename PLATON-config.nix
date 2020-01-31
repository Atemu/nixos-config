{ config, pkgs, ... }:

{
  imports = [
    # TODO make this a configurable option, e.g. meta.isDesktop = true
    ./desktop.nix
  ];

  boot.loader.timeout = 1;

  hardware.bluetooth.powerOnBoot = false;

  services.openssh.enable = true;

  programs.mosh.enable = true;

  networking.networkmanager.wifi.powersave = true;

  virtualisation.docker.enable = true;

  services.fprintd.enable = true;

  system.stateVersion = "19.09"; # Did you read the comment?
}
