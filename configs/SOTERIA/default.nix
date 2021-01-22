{ config, pkgs, ... }:

{
  imports = [
    ../../common.nix

    ./storage.nix

    ../../hardware/J4105M.nix
  ];

  custom.hostName = "SOTERIA";

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

  boot.initrd.network.ssh.authorizedKeys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDEXcFOT69BeaMxLSYOpgHxbHVcPR0DYpSWZDGYpxJ/uFdG3S6ZXiCVUhSeRMaDGtcsEcx+3Uz3rQaRaqq5OQsBwjDLYI/5Dy1GpH8oFLgZUfhBEriCbePrASJoRVMcL1KT/w8hIHM1ZbWqw9rfxDp2WNYNQL0UcrV9zlpLEyddSg6YBNaekxKtRjoSmsKvdarGVu6ffO46LNlaktXOFDoVOHEnDoG86oZv7r7CSJv/RFf7OP4HOchQx7X+F+CEeZvzweqtrebFXj3Pda8hWM2rFkPgSAMA4S5oPivoRpuKuEht9MQSRiLh37zl/NFH8KaI19on+X5UDiV+sbNork2t atemu@PLATON"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH3J1F+a1lSq05KPiH0gdZkx9q5w8XHfwqB3JfCzSzAV atemu@HEPHAISTOS"
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

  system.stateVersion = "19.09"; # Did you read the comment?
}

