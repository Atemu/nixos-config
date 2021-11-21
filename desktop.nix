{ config, pkgs, lib, ... }:

with lib;

{
  options.custom.desktop = {
    enable = mkEnableOption "my custom desktop";
  };

  config = mkIf config.custom.desktop.enable {
    boot.kernel.sysctl = { "kernel.sysrq" = 1; };

    sound.enable = true;
    services.pipewire.enable = true;
    services.pipewire.pulse.enable = true;
    services.pipewire.alsa.enable = true;
    services.pipewire.alsa.support32Bit = true;

    # The Steam client needs 32bit libraries
    # TODO only enable these if Steam is enabled
    hardware.opengl.driSupport32Bit = true;

    # Disable annoying GUI password popup and console error message when using ssh
    programs.ssh.askPassword = "";

    services.physlock.enable = true;
    services.physlock.allowAnyUser = true;
    services.physlock.disableSysRq = false; # Default. Is this actually a security concern?

    services.xserver.enable = true;
    services.xserver.displayManager.startx.enable = true;

    services.xserver.windowManager.i3.enable = true;
    services.xserver.displayManager.defaultSession = "none+i3";
    services.xserver.windowManager.i3.extraPackages = with pkgs; [
      dmenu
    ];

    programs.sway.enable = true;
    programs.sway.extraPackages = with pkgs; [
      bemenu
      qt5.qtwayland
      xwayland
    ];
    programs.sway.extraSessionCommands = ''
      [ -e ~/.wprofile ] && source ~/.wprofile
    '';

    services.xserver.layout = "us";
    services.xserver.xkbVariant = "altgr-intl";

    services.xserver.xkbOptions = "caps:escape";

    services.xserver.autoRepeatDelay = 224;
    services.xserver.autoRepeatInterval = 24;

    services.xserver.libinput = {
      touchpad.naturalScrolling = false;
      touchpad.disableWhileTyping = true;
      touchpad.accelProfile = "flat";
      mouse.accelProfile = "flat";
      enable = true;
    };

    fonts.fonts = with pkgs; [
      # My preferred monospace font
      hasklig # source-code-pro with ligatures

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
        "Source Code Pro"
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

    networking.networkmanager.enable = true;

    networking.networkmanager.logLevel = "INFO"; # Prints useful info to journalctl
    networking.networkmanager.wifi.macAddress = "stable"; # TODO what exactly does this mean?
    networking.networkmanager.wifi.scanRandMacAddress = true; # default
    networking.networkmanager.unmanaged = [ "docker0" "virbr0" "anbox0" ];

    services.emacs.enable = true;
    services.emacs.package = config.custom.emacs;

    programs.java.enable = true;

    services.urxvtd.enable = true;
  };
}
