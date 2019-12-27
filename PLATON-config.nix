# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  boot.loader.timeout = 1;
  boot.kernel.sysctl = { "kernel.sysrq" = 1; };

  hardware.bluetooth.powerOnBoot = false;

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.

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
  networking.networkmanager.enable = true;
  networking.networkmanager.dhcp = "dhclient";
  networking.networkmanager.logLevel = "INFO"; # Prints useful info to journalctl
  networking.networkmanager.wifi.backend = "iwd";
  networking.networkmanager.wifi.macAddress = "stable"; # TODO what exactly does this mean?
  networking.networkmanager.wifi.powersave = true;
  networking.networkmanager.wifi.scanRandMacAddress = true; # default
  networking.networkmanager.unmanaged = [ "docker0" "virbr0" ];

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  virtualisation.docker.enable = true;

  services.fprintd.enable = true;

  services.physlock.enable = true;
  services.physlock.allowAnyUser = true;
  services.physlock.disableSysRq = false; # Default. Is this actually a security concern?

  # Enable the X11 windowing system.
  # services.xserver.enable = true;
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e";
  services.xserver.enable = true;
  services.xserver.displayManager.startx.enable = true;

  services.xserver.windowManager.bspwm.enable = true;
  services.xserver.desktopManager.default = "none+bspwm";

  services.xserver.layout = "us";

  services.xserver.xkbOptions = "caps:escape";

  services.xserver.autoRepeatDelay = 224;
  services.xserver.autoRepeatInterval = 24;

  services.xserver.libinput.enable = true;
  services.xserver.libinput.naturalScrolling = false;

  services.xserver.desktopManager.wallpaper.mode = "fill";

  fonts.fonts = with pkgs; [
    uni-vga
    # Japanese fonts
    # Recommended by https://functor.tokyo/blog/2018-10-01-japanese-on-nixos
    carlito
    dejavu_fonts
    ipafont
    kochi-substitute
    source-code-pro
    ttf_bitstream_vera
  ];
  fonts.fontconfig.defaultFonts = {
    monospace = [
      "DejaVu Sans Mono"
      "IPAGothic"
    ];
    sansSerif = [
      "DejaVu Sans"
      "IPAPGothic"
    ];
    serif = [
      "DejaVu Serif"
      "IPAPMincho"
    ];
  };

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

