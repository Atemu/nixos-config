# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  boot.loader.grub.devices = [ "/dev/disk/by-id/ata-OCZ-TRION100_95EB50GYKMFX" ];

  networking.hostName = "KYKLOPS";
  boot.supportedFilesystems = [ "zfs" ];
  networking.hostId = "32ECBB16"; # crc32 of 'KYKLOPS'
  boot.zfs.forceImportAll = false;
  boot.zfs.forceImportRoot = false;

  boot.initrd.luks.devices = {
    TRION100-crypt = {
      device = "/dev/disk/by-uuid/140c8ebf-0664-47d6-8c71-cf9ef655efe0";
    };
    WD10EADS-crypt = {
      device = "/dev/disk/by-uuid/90fcb44c-275a-4641-99c6-9c36b753f283";
    };
    WD10EZEX-crypt = {
      device = "/dev/disk/by-uuid/41c3bb59-d732-4e53-99c5-4ab346f143b9";
    };
    ST1000DM003-crypt = {
      device = "/dev/disk/by-uuid/b22bbe9d-3513-4d93-81ee-6ce60da0bab1";
    };
    ST2000DM006-crypt = {
      device = "/dev/disk/by-uuid/e9b4abff-8f8d-4bd1-a366-1938a89c12bf";
    };
  };
  boot.initrd.network.enable = true;
  boot.initrd.network.ssh.enable = true;
  # # nix-shell -p dropbear --command "dropbearkey -t rsa -f /root/boot.initrd.network.ssh.hostRSAKey"
  boot.initrd.network.ssh.hostRSAKey = "/root/boot.initrd.network.ssh.hostRSAKey";
  # Required to make it a "different" machine from the ssh client's POV, see https://github.com/NixOS/nixpkgs/pull/10460#issuecomment-155433336
  boot.initrd.network.ssh.port = 2222;
  boot.initrd.network.ssh.authorizedKeys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDEXcFOT69BeaMxLSYOpgHxbHVcPR0DYpSWZDGYpxJ/uFdG3S6ZXiCVUhSeRMaDGtcsEcx+3Uz3rQaRaqq5OQsBwjDLYI/5Dy1GpH8oFLgZUfhBEriCbePrASJoRVMcL1KT/w8hIHM1ZbWqw9rfxDp2WNYNQL0UcrV9zlpLEyddSg6YBNaekxKtRjoSmsKvdarGVu6ffO46LNlaktXOFDoVOHEnDoG86oZv7r7CSJv/RFf7OP4HOchQx7X+F+CEeZvzweqtrebFXj3Pda8hWM2rFkPgSAMA4S5oPivoRpuKuEht9MQSRiLh37zl/NFH8KaI19on+X5UDiV+sbNork2t atemu@PLATON" ];

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

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget vim rxvt_unicode.terminfo
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.atemu = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.09"; # Did you read the comment?

}

