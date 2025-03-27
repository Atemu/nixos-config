{ ... }:

{
  imports = [
    ../../common.nix

    ./storage.nix

    ../../hardware/J4105M.nix
  ];

  networking.hostName = "SOTERIA";

  boot.initrd.network.enable = true;
  boot.initrd.network.udhcpc.extraArgs = [
    "-t"
    "20"
  ];
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
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIcU6XG0H5Fs0jl9mHiPWwI3BdHz4Uf9CIAc94eklV9Y atemu@THESEUS"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHK/Gx95TAvE5GmEuLwWgOQpwjkWNaVavprNlFOuCjFI atemu@PLATON"
  ];

  boot.initrd.network.postCommands = ''
    # Automatically ask for the password on SSH login
    echo 'cryptsetup-askpass || echo "Unlock was successful; exiting SSH session" && exit 1' >> /root/.profile
  '';

  # Uses systemd-networkd for basic DHCP purposes
  networking.useDHCP = true;
  networking.useNetworkd = true;

  # Set the metric to < 1000 so that my tailscale patch works properly.
  # FIXME make the tailscale patch install the routes with metric > 1024
  systemd.network.networks."99-ethernet-default-dhcp" = {
    dhcpV4Config.RouteMetric = 925;
    ipv6AcceptRAConfig.RouteMetric = 925;
  };

  # TODO do this for all machines
  systemd.targets.rescue.wants = [
    "sshd.service"
    "network.target"
    "tailscaled.service"
  ];

  programs.mosh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  services.tailscale.useRoutingFeatures = "server"; # This is an exit node

  custom.remotebuild.enable = true;
  custom.remotebuild.builders.cccda = true;

  custom.hedgedoc.enable = true;
  custom.virtualHosts.hedgedoc.onPrimaryDomain = true;

  custom.mealie.enable = true;
  custom.virtualHosts.mealie.onPrimaryDomain = true;

  custom.paperless.enable = true;
  custom.paperless.autoExport = true;
  custom.virtualHosts.paperless.onPrimaryDomain = true;

  custom.piped.enable = true;
  custom.piped.onPrimaryDomain = true;
  custom.piped.feedFetchHack = true;

  custom.actualbudget.enable = true;
  custom.virtualHosts.actualbudget.onPrimaryDomain = true;

  custom.immich.enable = true;
  # Images assets are stored on Data disks
  custom.immich.libraryDir = "/Volumes/Data/Immich/library/";
  custom.immich.externalLibraryDir = "/Volumes/Data/Pictures/";
  custom.immich.virtualHost.onPrimaryDomain = true;

  custom.nextcloud.enable = true;
  custom.nextcloud.code.enable = true;
  custom.nextcloud.virtualHost.onPrimaryDomain = true;

  services.iperf3.enable = true;
  services.iperf3.openFirewall = true;

  virtualisation.docker.enable = true;

  # Acts as a server for my clients to replicate to
  custom.replication.enable = true;

  system.stateVersion = "19.09"; # Did you read the comment?
}
