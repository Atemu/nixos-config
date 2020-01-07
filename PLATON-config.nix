{ config, pkgs, ... }:

{
  boot.loader.timeout = 1;

  boot.kernel.sysctl = { "kernel.sysrq" = 1; };

  hardware.bluetooth.powerOnBoot = false;

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  services.openssh.enable = true;

  # Disable annoying GUI password popup and console error message when using ssh
  programs.ssh.askPassword = "";

  programs.mosh.enable = true;

  services.emacs.enable = true;

  networking.networkmanager.enable = true;

  networking.networkmanager.dhcp = "dhclient";
  networking.networkmanager.logLevel = "INFO"; # Prints useful info to journalctl
  networking.networkmanager.wifi.backend = "iwd";
  networking.networkmanager.wifi.macAddress = "stable"; # TODO what exactly does this mean?
  networking.networkmanager.wifi.powersave = true;
  networking.networkmanager.wifi.scanRandMacAddress = true; # default
  networking.networkmanager.unmanaged = [ "docker0" "virbr0" ];

  # Enable dnscrypt-proxy-2 via a Docker image
  # FIXME: Use the native Nix dnscrypt-proxy-2 module when it's available
  docker-containers.dnscrypt-proxy = {
    image = "atemu12/dnscrypt-proxy-2";
    ports = [ "53:53/udp" ];
    volumes = [ "dnscrypt-blacklist:/blacklist/:ro" ];
  };
  networking.resolvconf.useLocalResolver = true;

  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "zfs";

  services.fprintd.enable = true;

  hardware.brightnessctl.enable = true;

  services.physlock.enable = true;
  services.physlock.allowAnyUser = true;
  services.physlock.disableSysRq = false; # Default. Is this actually a security concern?

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

  system.stateVersion = "19.09"; # Did you read the comment?
}
