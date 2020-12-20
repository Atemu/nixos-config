{ config, ... }:

{
  imports = [
    ./storage.nix
  ];

  services.openssh.enable = true;

  programs.mosh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "20.03";
}
