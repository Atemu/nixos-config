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

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "22.11";
}
