{ config, pkgs, ... }:

{
  imports = [
    ../../desktop.nix
    ./storage.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_lqx;

  services.xserver.videoDrivers = [ "nvidiaBeta" ];

  hardware.steam-hardware.enable = true;

  services.sshd.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    qemuOvmf = true;
    qemuRunAsRoot = false;
  };

  virtualisation.docker.enable = true;

  programs.adb.enable = true;

  system.stateVersion = "20.09";
}
