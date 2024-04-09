{ config, pkgs, lib, ... }:

{
  imports = [
    ../../common.nix

    ./storage.nix

    ../../hardware/B650.nix
  ];

  networking.hostName = "HEPHAISTOS";

  custom.desktop.enable = true;

  custom.gaming.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;

  boot.initrd.systemd.enable = true;

  services.sshd.enable = true;

  # Scanner
  # TODO refactor into module
  hardware.sane.enable = true;
  environment.systemPackages = with pkgs; [
    img2pdf
  ];

  virtualisation.docker.enable = true;

  programs.adb.enable = true;

  custom.dnscrypt.enable = true;

  system.stateVersion = "20.09";
}
