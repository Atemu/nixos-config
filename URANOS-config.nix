{ config, ... }:

{
  services.openssh.enable = true;

  programs.mosh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  virtualisation.docker.enable = true;

  docker-containers."bz" = {
    image = "atemu12/backblaze-personal-wine-docker";
    ports =  [ "5900:5900" ];
    volumes = [
      "/srv/bz/wine:/wine/"
      "/srv/bz/upload/:/wine/drive_d/:ro"
      "/srv/bz/bzvol:/wine/drive_d/.bzvol"
    ];
  };

  services.logind.lidSwitch = "ignore";

  system.stateVersion = "20.03";
}
