{ pkgs, ... }:

{
  imports = [
    ../../common.nix

    ./storage.nix

    ../../hardware/B650.nix
  ];

  networking.hostName = "HEPHAISTOS";

  custom.desktop.enable = true;
  custom.desktop.hypr.enable = true;

  custom.gaming.enable = true;
  custom.gaming.steamvr.unprivilegedHighPriorityQueue = true;

  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;

  boot.initrd.systemd.enable = true;

  # Scanner
  # TODO refactor into module
  hardware.sane.enable = true;
  environment.systemPackages = with pkgs; [
    img2pdf
  ];

  custom.dnscrypt.enable = true;

  system.stateVersion = "20.09";
}
