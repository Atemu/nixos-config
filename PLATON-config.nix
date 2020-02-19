{ config, pkgs, ... }:

{
  imports = [
    # TODO make this a configurable option, e.g. meta.isDesktop = true
    ./desktop.nix
  ];

  hardware.bluetooth.powerOnBoot = false;

  services.tlp.enable = true;

  services.undervolt.enable = true;

  networking.networkmanager.wifi.powersave = true;

  systemd.services.ModemManager.wantedBy = [ "network.target" ];

  virtualisation.docker.enable = true;

  services.fprintd.enable = true;

  programs.java.enable = true;

  system.stateVersion = "19.09"; # Did you read the comment?
}
