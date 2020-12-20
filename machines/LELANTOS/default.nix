{
  imports = [
    ./storage.nix
  ];

  services.openssh.enable = true;
  programs.mosh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  custom.dnscrypt.enable = true;
  services.dnscrypt-proxy2.settings.listen_addresses = [ "0.0.0.0:53" ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
