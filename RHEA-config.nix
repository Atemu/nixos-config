{ config, ... }:

{
  imports = [
    ./desktop.nix
  ];

  services.openssh.enable = true;

  programs.mosh.enable = true;

  system.stateVersion = "19.09";
}
