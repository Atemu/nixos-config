{ config, ... }:

{
  imports = [
    ./storage.nix
  ];

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
      "/srv/bz/bzthread:/wine/drive_c/ProgramData/Backblaze/bzdata/bzthread"
    ];
    extraDockerOptions = [ "--init" ];
  };

  services.logind.lidSwitch = "ignore";

  system.stateVersion = "20.03";
}
