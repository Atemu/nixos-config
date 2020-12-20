{ config, modulesPath ... }:

{
  imports = [
    ../../common.nix

    ./storage.nix

    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  custom.hostName = "RHEA";

  services.openssh.enable = true;

  programs.mosh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "20.03";
}
