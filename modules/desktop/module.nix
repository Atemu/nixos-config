{ config, pkgs, lib, ... }:

let
  this = config.custom.desktop;
in

{
  options.custom.desktop = {
    enable = lib.mkEnableOption "my custom desktop";
    tablet = lib.mkEnableOption "tablet variant";
    hypr.enable = lib.mkEnableOption "hyprland variant";
    hypr.hypridle-power = lib.mkEnableOption ''
      a hypridle daemon that sets the power-profiles-daemon power profile to
      `power-saver` on 2s idle and restores it to `performance` when not idle.
    '';
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
    systemd.user.targets.hypr-session = {
      bindsTo = [ "graphical-session.target" ];
      wants = [ "graphical-session-pre.target" ];
      after = [ "graphical-session-pre.target" ];
    };

    services.hypridle.package =
      if lib.versionOlder pkgs.hypridle.version "2.1.8" || pkgs.hypridle.version == "2.1.8" then
        # Unreleased version that supports systemd-inhibit
        pkgs.hypridle.overrideAttrs (old: {
          src = pkgs.fetchFromGitHub {
            owner = "hyprwm";
            repo = "hypridle";
            rev = "cc23f97836adbba1abc8edd48169fb1f1f698c32";
            hash = "sha256-b/j875k6RrxQLtbW+NCLw7NLToMd9KDYywjtUoihpq4=";
          };
          version = "2.1.8-unstable-2024-09-25";
          buildInputs = old.buildInputs ++ [
            pkgs.hyprutils
          ];
        })
      else
        pkgs.hypridle;
    systemd.user.services.hypridle = {
      serviceConfig = {
        ExecStart = lib.getExe config.services.hypridle.package;
      };
      path = with pkgs; [
        bash
        brightnessctl
        config.programs.hyprland.package
        procps
        swaylock
      ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      wantedBy = [ "hypr-session.target" ];
    };
    # A second hypridle daemon that activates power savings after 2s of idle
    systemd.user.services.hypridle-power = lib.mkIf this.hypr.hypridle-power {
      serviceConfig = {
        # Quiet because I don't care about logging these actions and they're very frequent
        ExecStart = "${lib.getExe config.services.hypridle.package} -c ${./hypridle-power.conf} --quiet";
      };
      path = [ config.services.power-profiles-daemon.package ];
      partOf = [ "graphical-session.target" ];
      after = [
        "graphical-session.target"
        # Let the regular hypridle register itself first to avoid any issues/races
        "hypridle.service"
      ];
      wantedBy = [ "hypr-session.target" ];
    };
    assertions = [
      {
        assertion = this.hypr.hypridle-power -> config.services.power-profiles-daemon.enable;
        message = "custom.desktop.hypr.hypridle-power requires power-profiles-deamon";
      }
    ];

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

    # Just utterly broken. See
    # https://github.com/NixOS/nixpkgs/issues/180175#issuecomment-1660635001
    systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;

    services.emacs.enable = true;
    # Emacs likes to get itself stuck waiting on user input or some shit on the
    # rather explicit (kill-emacs) command. Let's not tolerate that.
    systemd.user.services.emacs.serviceConfig.TimeoutStopSec = "10s";
  });
}
