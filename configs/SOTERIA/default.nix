{ config, pkgs, ... }:

{
  imports = [
    ../../common.nix

    ./storage.nix

    ../../hardware/J4105M.nix
  ];

  custom.hostName = "SOTERIA";

  boot.kernelPackages = pkgs.linuxPackages_5_15;

  boot.initrd.network.enable = true;
  boot.initrd.network.udhcpc.extraArgs = [ "-t" "20" ];
  boot.initrd.network.ssh.enable = true;

  # mkdir /etc/secrets/initrd -p
  # chmod 700 -R /etc/secrets/
  # sudo ssh-keygen -t ed25519 -f /etc/secrets/initrd/ssh_host_ed25519_key
  boot.initrd.network.ssh.hostKeys = [
    "/etc/secrets/initrd/ssh_host_ed25519_key"
  ];

  # Required to make it a "different" machine from the ssh client's POV.
  # See https://github.com/NixOS/nixpkgs/pull/10460#issuecomment-155433336
  boot.initrd.network.ssh.port = 2222;

  # TODO Add trusted keys option
  boot.initrd.network.ssh.authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH3J1F+a1lSq05KPiH0gdZkx9q5w8XHfwqB3JfCzSzAV atemu@HEPHAISTOS"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIcU6XG0H5Fs0jl9mHiPWwI3BdHz4Uf9CIAc94eklV9Y atemu@LYKOURGOS"
  ];

  boot.initrd.network.postCommands = ''
    # Automatically ask for the password on SSH login
    echo 'cryptsetup-askpass || echo "Unlock was successful; exiting SSH session" && exit 1' >> /root/.profile
  '';

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = true; # required for DHCP in boot.initrd.network!

  services.openssh.enable = true;

  programs.mosh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  custom.dnscrypt.enable = true;
  custom.dnscrypt.listen = true;

  services.grocy = {
    hostName = config.custom.hostName;
    enable = true;
    settings = {
      currency = "EUR";
      culture = "en";
      calendar.firstDayOfWeek = 1; # Monday
    };
    nginx.enableSSL = false;
  };
  networking.firewall.allowedTCPPorts = [ 80 ];
  # FIXME Grocy needs a PHP version with OpenSSL 1.1.1?
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1t"
  ];

  custom.paperless.enable = true;

  services.iperf3.enable = true;
  services.iperf3.openFirewall = true;

  virtualisation.docker.enable = true;

  system.stateVersion = "19.09"; # Did you read the comment?
}

