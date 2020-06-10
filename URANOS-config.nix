{ config, ... }:

{
  services.openssh.enable = true;

  programs.mosh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  virtualisation.docker.enable = true;

  system.stateVersion = "20.03";
}
