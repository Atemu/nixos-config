{
  imports = [
    ../../common.nix

    ./storage.nix

    ../../hardware/RPI2.nix
  ];

  networking.hostName = "LELANTOS";

  services.openssh.enable = true;
  programs.mosh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  custom.dnscrypt.enable = true;
  custom.dnscrypt.listen = true;
}
