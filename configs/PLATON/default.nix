{ ... }:

{
  imports = [
    ../../common.nix

    ./storage.nix

    ../../hardware/Q775.nix
  ];

  networking.hostName = "PLATON";

  custom.desktop.enable = true;
  custom.desktop.tablet = true;

  hardware.bluetooth.powerOnBoot = false;

  services.undervolt.enable = true;
  # It don't want the logspam, this is only needed because undervolt resets on boot
  systemd.timers.undervolt.enable = false;
  systemd.services.undervolt.wantedBy = [
    "post-resume.target"
    "multi-user.target"
  ];
  systemd.services.undervolt.after = [ "post-resume.target" ];

  networking.networkmanager.wifi.powersave = true;

  custom.dnscrypt.enable = true;

  custom.remotebuild.enable = true;
  custom.remotebuild.builders.cccda = true;

  system.stateVersion = "19.09"; # Did you read the comment?
}
