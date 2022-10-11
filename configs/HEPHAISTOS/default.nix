{ config, pkgs, lib, ... }:

{
  imports = [
    ../../common.nix

    ./storage.nix

    ../../hardware/B550.nix
  ];

  custom.hostName = "HEPHAISTOS";

  custom.desktop.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;

  services.xserver.videoDrivers = [ "amdgpu" ];
  services.xserver.deviceSection = ''
    Option "TearFree" "False"
    Option "VariableRefresh" "True"
  '';

  hardware.steam-hardware.enable = true;

  services.ratbagd.enable = true;

  services.sshd.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    qemu.ovmf.enable = true;
    qemu.runAsRoot = false;
  };
  # Libvirt takes forever to start, socket activate it when I actually need it
  systemd.services.libvirtd.wantedBy = [ ];
  # Don't need this feature.
  systemd.services.libvirt-guests.wantedBy = lib.mkForce [ ];

  virtualisation.docker.enable = true;
  # Makes Docker socket activated, only starting it after I use it once
  systemd.services.docker.wantedBy = lib.mkForce [ ]; # TODO put in some sort of common module

  programs.adb.enable = true;

  custom.dnscrypt.enable = true;

  system.stateVersion = "20.09";
}
