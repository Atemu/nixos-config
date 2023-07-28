{ config, pkgs, lib, ... }:

with lib;

let
  tablet = config.custom.desktop.tablet;
in

{
  options.custom.desktop = {
    enable = mkEnableOption "my custom desktop";
    tablet = mkEnableOption "tablet variant";
  };

  config = mkIf config.custom.desktop.enable {
    boot.kernel.sysctl = { "kernel.sysrq" = 1; };

    sound.enable = true;

    hardware.pulseaudio.enable = false;
    services.pipewire.enable = true;
    services.pipewire.pulse.enable = true;
    services.pipewire.alsa.enable = true;
    services.pipewire.alsa.support32Bit = true;

    # ladspa only looks in the lib/ladspa subdir
    systemd.user.services.pipewire.environment.LADSPA_PATH = lib.makeSearchPathOutput "lib" "lib/ladspa" (with pkgs; [
      rnnoise-plugin
      lsp-plugins
    ]);

    # Disable annoying GUI password popup and console error message when using ssh
    programs.ssh.askPassword = "";

    services.xserver.enable = true;
    services.xserver.displayManager.sddm.enable = !tablet;
    services.xserver.displayManager.gdm.enable = tablet;

    services.xserver.displayManager.defaultSession = if tablet then "gnome" else "none+i3";

    services.xserver.windowManager.i3.enable = true;
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

    services.xserver.desktopManager.gnome.enable = tablet;
    environment.gnome.excludePackages = with pkgs; [
      orca
    ];

    environment.systemPackages = with pkgs; [
      write_stylus
    ];

    custom.packages.allowedUnfree = [
      "write_stylus"
    ];

    services.dbus.enable = true;

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      # GNOME adds xdg-desktop-portal-gtk on its own which causes a collision
      extraPortals = lib.optionals (!config.services.xserver.desktopManager.gnome.enable) [
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

    services.xserver.wacom.enable = tablet;

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
  };
}
