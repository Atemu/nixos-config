{ config, pkgs, lib, ... }:

{
  imports = [
    ../../common.nix

    ./storage.nix

    ../../hardware/HYPERV.nix
  ];

  custom.hostName = "HYPERION";

  custom.desktop.enable = true;

  virtualisation.docker.enable = true;
  # Makes Docker socket activated, only starting it after I use it once
  systemd.services.docker.wantedBy = lib.mkForce [ ]; # TODO put in some sort of common module

  programs.adb.enable = true;

  system.stateVersion = "21.11";
}
