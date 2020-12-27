{ config, pkgs, lib, ... }:

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
  # Makes Docker socket activated, only starting it after I use it once
  systemd.services.docker.wantedBy = lib.mkForce [ ]; # TODO put in some sort of common module

  programs.adb.enable = true;

  system.stateVersion = "20.09";
}
