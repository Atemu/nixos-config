{
  imports = [
    ./storage.nix
  ];

  services.openssh.enable = true;
  programs.mosh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  custom.dnscrypt.enable = true;
  custom.dnscrypt.listen = true;
}
