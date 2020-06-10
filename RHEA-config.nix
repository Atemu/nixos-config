{ config, ... }:

{
  # TODO find a nicer way to set the same value for all users automatically
  users.users.atemu.hashedPassword = "$6$66BjFoGY9Ckwnrr$xaj10.vNEBy4Rg5gCplROGuwZL6M3K4IQqLhEYW1ZnMMkBqm9VSENmVARmAJ.2a2YrDJeX79KSCag8.8rcV6e/";
  users.users.root.hashedPassword = "$6$66BjFoGY9Ckwnrr$xaj10.vNEBy4Rg5gCplROGuwZL6M3K4IQqLhEYW1ZnMMkBqm9VSENmVARmAJ.2a2YrDJeX79KSCag8.8rcV6e/";

  services.openssh.enable = true;

  programs.mosh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "19.09";
}
