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
  services.xserver.deviceSection = ''
    Option "VariableRefresh" "True"
  '';

  hardware.steam-hardware.enable = true;

  services.sshd.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    qemuOvmf = true;
    qemuRunAsRoot = false;
  };
  # Libvirt takes forever to start, socket activate it when I actually need it
  systemd.services.libvirtd.wantedBy = [ ];
  # Don't need this feature.
  systemd.services.libvirt-guests.wantedBy = lib.mkForce [ ];

  virtualisation.docker.enable = true;
  # Makes Docker socket activated, only starting it after I use it once
  systemd.services.docker.wantedBy = lib.mkForce [ ]; # TODO put in some sort of common module

  # Don't wait for something as unreliable as networking before letting me use my system
  systemd.targets.network-online.enable = false;

  programs.adb.enable = true;

  system.stateVersion = "20.09";
}
