{ config, pkgs, ... }:

{
  imports = [
    ./desktop.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_zen;

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
