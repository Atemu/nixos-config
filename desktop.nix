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

    services.xserver.enable = true;
    services.xserver.displayManager.sddm.enable = true;

    services.xserver.windowManager.i3.enable = true;
    services.xserver.displayManager.defaultSession = "sway";
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

    services.dbus.enable = true;

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [
        # TODO I'd prefer to use `pkgs.xdg-desktop-portal-kde'. This currently
        # causes Firefox to go into a sort of QT compatibility mode which
        # disables my Emacs gtk key-theme however, so not an option
        pkgs.xdg-desktop-portal-gtk
      ];
    };

    services.xserver.layout = "us";
    services.xserver.xkbVariant = "altgr-intl";

    services.xserver.xkbOptions = "caps:escape";

    services.xserver.autoRepeatDelay = 224;
    services.xserver.autoRepeatInterval = 24;

    services.xserver.libinput = {
      touchpad.naturalScrolling = false;
      touchpad.disableWhileTyping = true;
      touchpad.accelProfile = "flat";
      touchpad.middleEmulation = true;
      mouse.accelProfile = "flat";
      mouse.middleEmulation = false;
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
