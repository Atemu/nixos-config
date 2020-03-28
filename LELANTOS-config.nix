{
  services.openssh.enable = true;
	programs.mosh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  services.dnscrypt-proxy2.enable = true;
}
