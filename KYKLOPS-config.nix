# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  boot.initrd.network.enable = true;
  boot.initrd.network.ssh.enable = true;

  # This sets the hostRSAKey to be an empty file which later gets overwritten
  # with the actual key from an initrd on /boot/.
  # This way the actual key is kept out of the world-readable nix store
  # and SSH gets configured to use the RSA key.
  # Without this option set, ssh would try to use an (non-existent) ECDSA key
  # eventhough the RSA key file exists.
  # FIXME: Use native Nix secrets for this when they come out
  boot.initrd.network.ssh.hostRSAKey = pkgs.writeTextFile {name = "empty"; text = "";};

  # Keyfile initrd generation commands:
  # # nix-shell -p dropbear --command "dropbearkey -t rsa -f /root/etc/dropbear/dropbear_rsa_host_key"
  # # cd /root/ ; echo ./etc/dropbear/dropbear_rsa_host_key | cpio -o -H newc -R +0:+0 --reproducible | gzip -9 > /boot/extraInitrd.gz
  boot.loader.grub.extraInitrd = "/boot/extraInitrd.gz";

  # Required to make it a "different" machine from the ssh client's POV.
  # See https://github.com/NixOS/nixpkgs/pull/10460#issuecomment-155433336
  boot.initrd.network.ssh.port = 2222;

  boot.initrd.network.ssh.authorizedKeys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDEXcFOT69BeaMxLSYOpgHxbHVcPR0DYpSWZDGYpxJ/uFdG3S6ZXiCVUhSeRMaDGtcsEcx+3Uz3rQaRaqq5OQsBwjDLYI/5Dy1GpH8oFLgZUfhBEriCbePrASJoRVMcL1KT/w8hIHM1ZbWqw9rfxDp2WNYNQL0UcrV9zlpLEyddSg6YBNaekxKtRjoSmsKvdarGVu6ffO46LNlaktXOFDoVOHEnDoG86oZv7r7CSJv/RFf7OP4HOchQx7X+F+CEeZvzweqtrebFXj3Pda8hWM2rFkPgSAMA4S5oPivoRpuKuEht9MQSRiLh37zl/NFH8KaI19on+X5UDiV+sbNork2t atemu@PLATON" ];

  boot.initrd.network.postCommands = ''
    # Make initrd SSH use the host RSA key from the extraInitrd.
    cp /dropbear_rsa_host_key /etc/dropbear/
    # Automatically ask for the password on SSH login
    echo 'cryptsetup-askpass' >> /root/.profile
  '';

  boot.initrd.postMountCommands = ''
    for int in /sys/class/net/*/
      do ip link set `basename $int` down
    done
  '';

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n = {
  #   consoleFont = "Lat2-Terminus16";
  #   consoleKeyMap = "us";
  #   defaultLocale = "en_US.UTF-8";
  # };

  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  programs.mosh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  # services.xserver.libinput.enable = true;

  # Enable the KDE Desktop Environment.
  # services.xserver.displayManager.sddm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.09"; # Did you read the comment?

}

