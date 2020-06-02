{ config, ... }:

{
  services.openssh.enable = true;

  programs.mosh.enable = true;

  system.stateVersion = "20.03";
}
