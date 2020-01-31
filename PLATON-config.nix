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

  networking.networkmanager.enable = true;

  networking.networkmanager.logLevel = "INFO"; # Prints useful info to journalctl
  networking.networkmanager.wifi.backend = "iwd";
  networking.networkmanager.wifi.macAddress = "stable"; # TODO what exactly does this mean?
  networking.networkmanager.wifi.powersave = true;
  networking.networkmanager.wifi.scanRandMacAddress = true; # default
  networking.networkmanager.unmanaged = [ "docker0" "virbr0" ];

  # Enable dnscrypt-proxy-2 via a Docker image
  # FIXME: Use the native Nix dnscrypt-proxy-2 module when it's available
  docker-containers.dnscrypt-proxy = {
    image = "atemu12/dnscrypt-proxy-2";
    ports = [ "53:53/udp" ];
    volumes = [ "dnscrypt-blacklist:/blacklist/:ro" ];
  };
  networking.resolvconf.useLocalResolver = true;

  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "zfs";

  services.fprintd.enable = true;

  system.stateVersion = "19.09"; # Did you read the comment?
}
