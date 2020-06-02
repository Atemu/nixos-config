{ config, ... }:

{
  services.openssh.enable = true;

  system.stateVersion = "20.03";
}
