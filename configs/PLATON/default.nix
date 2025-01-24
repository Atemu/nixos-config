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
  # I don't exactly understand why but if undervolt needs to be both after and
  # wanted by post-resume.target to be run on resume
  # Being wanted by the multi-user.target makes undervolt run on boot and
  # on generation switch in a live system
  systemd.services.undervolt.wantedBy = [ "post-resume.target" "multi-user.target" ];
  systemd.services.undervolt.after = [ "post-resume.target" ];

  networking.networkmanager.wifi.powersave = true;

  systemd.services.ModemManager.wantedBy = [ "network.target" ];

  virtualisation.docker.enable = true;

  custom.dnscrypt.enable = true;

  custom.remotebuild.enable = true;
  custom.remotebuild.builders.cccda = true;

  system.stateVersion = "19.09"; # Did you read the comment?
}
