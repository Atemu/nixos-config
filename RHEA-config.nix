{ config, ... }:

{
  services.openssh.enable = true;

  programs.mosh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "19.09";
}
