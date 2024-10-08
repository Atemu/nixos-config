{ config, pkgs, lib, ... }:

let
  this = config.custom.desktop;
in

{
  options.custom.desktop = {
    enable = lib.mkEnableOption "my custom desktop";
    tablet = lib.mkEnableOption "tablet variant";
    hypr.enable = lib.mkEnableOption "hyprland variant";
  };

  config = lib.mkIf this.enable (lib.optionalAttrs (lib.versionAtLeast lib.trivial.release "24.05") {
    boot.kernel.sysctl = { "kernel.sysrq" = 1; };

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

    services.pipewire.wireplumber.extraConfig.bluetooth-no-hw-volume = {
      "monitor.bluez.properties" = {
        "bluez5.enable-hw-volume" = false;
      };
    };

    # Upstream pipewire limits for realtime
    security.pam.loginLimits = [
      {
        domain = "@users";
        item = "rtprio";
        type = "-";
        value = "95";
      }
      {
        domain = "@users";
        item = "nice";
        type = "-";
        value = "-19";
      }
      {
        domain = "@users";
        item = "memlock";
        type = "-";
        value = "4194304";
      }
    ];

    # Disable annoying GUI password popup and console error message when using ssh
    programs.ssh.askPassword = "";

    services.xserver.enable = true;
    services.xserver.displayManager.gdm.enable = true;

    services.displayManager.defaultSession =
      if this.hypr.enable
      then "hyprland"
      else if this.tablet
      then "gnome"
      else "none+i3";

    services.xserver.windowManager.i3.enable = true;
    services.xserver.windowManager.i3.extraPackages = with pkgs; [
      dmenu
      i3lock
    ];

    programs.sway.enable = true;
    programs.sway.extraPackages = with pkgs; [
      bemenu
      dunst
      foot
      qt5.qtwayland
      swaylock
      xwayland
    ];
    programs.sway.extraSessionCommands = ''
      [ -e ~/.wprofile ] && source ~/.wprofile
    '';

    programs.hyprland.enable = this.hypr.enable;
    services.hypridle.enable = this.hypr.enable;

    services.xserver.desktopManager.gnome.enable = this.tablet;
    environment.gnome.excludePackages = with pkgs; [
      orca
    ];

    hardware.brillo.enable = true;

    environment.systemPackages = (with pkgs; [
      brightnessctl
      wofi
      wev
    ])
    ++ lib.optionals this.tablet (with pkgs; [
      write_stylus
    ]);
    custom.packages.allowedUnfree = lib.mkIf this.tablet [
      "write_stylus"
    ];

    services.dbus.enable = true;

    services.logind.extraConfig = "HandlePowerKey=suspend";

    xdg.portal = {
      enable = true;
      # Hyprland doesn't like wlr being present
      wlr.enable = if this.hypr.enable then lib.mkForce false else true;
      # GNOME adds xdg-desktop-portal-gtk on its own which causes a collision
      extraPortals = lib.mkIf (!config.services.xserver.desktopManager.gnome.enable) [
        # TODO I'd prefer to use `pkgs.xdg-desktop-portal-kde'. This currently
        # causes Firefox to go into a sort of QT compatibility mode which
        # disables my Emacs gtk key-theme however, so not an option
        pkgs.xdg-desktop-portal-gtk
      ];
    };

    services.xserver.xkb.layout = "us";
    services.xserver.xkb.variant = "altgr-intl";

    services.xserver.xkb.options = "caps:escape";

    services.xserver.autoRepeatDelay = 224;
    services.xserver.autoRepeatInterval = 24;

    services.libinput = {
      touchpad.naturalScrolling = false;
      touchpad.disableWhileTyping = true;
      touchpad.accelProfile = "flat";
      touchpad.middleEmulation = true;
      mouse.accelProfile = "flat";
      mouse.middleEmulation = false;
      enable = true;
    };

    services.xserver.wacom.enable = this.tablet;

    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    services.printing.enable = true;

    programs.ausweisapp.enable = true;
    programs.ausweisapp.openFirewall = true;

    programs.appimage.enable = true;
    programs.appimage.binfmt = true;

    fonts.packages = with pkgs; [
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

    # Speculative fix for https://github.com/NixOS/nixpkgs/issues/180175
    systemd.services.tailscaled.after = [ "NetworkManager-wait-online.service" ];

    services.emacs.enable = true;
  });
}
