{
  services.openssh.enable = true;
  programs.mosh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  services.dnscrypt-proxy2.enable = true;
  services.dnscrypt-proxy2.settings.listen_addresses = [ "0.0.0.0:53" ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
