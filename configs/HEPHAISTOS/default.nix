{ config, pkgs, ... }:

{
  imports = [
    ../../common.nix

    ./storage.nix

    ../../hardware/B550.nix
  ];

  custom.hostName = "HEPHAISTOS";

  custom.desktop.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_lqx;

  services.xserver.videoDrivers = [ "amdgpu" ];

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
