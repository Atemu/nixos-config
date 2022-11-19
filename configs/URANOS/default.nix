{ lib, ... }:

{
  imports = [
    ../../common.nix

    ./storage.nix

    ../../hardware/UTM.nix
  ];

  custom.hostName = "URANOS";

  services.openssh.enable = true;

  programs.mosh.enable = true;

  custom.vm.enable = true;

  system.stateVersion = "22.11";
}
