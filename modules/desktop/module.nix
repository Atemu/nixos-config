{
  config,
  pkgs,
  lib,
  ...
}:

let
  this = config.custom.desktop;

  # Create a service that is part of the hyprland session
  # TODO this should probably be a generic option instead
  mkHyprSessionService =
    conf:
    lib.mkMerge [
      conf
      {
        wantedBy = [ "wayland-session@Hyprland.target" ];
        after = [ "wayland-wm@Hyprland.service" ]; # TODO should this be wayland-wm-env@Hyprland.service instead?
        before = [ "wayland-session@Hyprland.target" ];
        partOf = [ "wayland-session@Hyprland.target" ];
        serviceConfig = {
          Slice = [ "session.slice" ];
        };
      }
    ];
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

  config = lib.mkIf this.enable (
    lib.optionalAttrs (lib.versionAtLeast lib.trivial.release "25.05") {
      boot.kernel.sysctl = {
        "kernel.sysrq" = 1;
      };

      services.pulseaudio.enable = false;
      services.pipewire.enable = true;
      services.pipewire.pulse.enable = true;
      services.pipewire.alsa.enable = true;
      services.pipewire.alsa.support32Bit = true;

      # ladspa only looks in the lib/ladspa subdir
      systemd.user.services.pipewire.environment.LADSPA_PATH =
        lib.makeSearchPathOutput "lib" "lib/ladspa"
          (
            with pkgs;
            [
              rnnoise-plugin
              lsp-plugins
            ]
          );

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
        if this.hypr.enable then
          "Hyprland-uwsm"
        else if this.tablet then
          "gnome"
        else
          "none+i3";

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
        wl-clipboard
        xwayland
      ];
      programs.sway.extraSessionCommands = ''
        [ -e ~/.wprofile ] && source ~/.wprofile
      '';

      programs.hyprland.enable = this.hypr.enable;

      programs.uwsm.enable = true;
      programs.uwsm.waylandCompositors.Hyprland = {
        binPath = lib.getExe config.programs.hyprland.package;
        prettyName = "Hyprland";
      };

      systemd.user.services.hypridle = lib.mkIf this.hypr.enable (mkHyprSessionService {
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
      });

      # A second hypridle daemon that activates power savings after 2s of idle
      systemd.user.services.hypridle-power = lib.mkIf this.hypr.hypridle-power (mkHyprSessionService {
        serviceConfig = {
          # Quiet because I don't care about logging these actions and they're very frequent
          ExecStart = "${lib.getExe config.services.hypridle.package} -c ${./hypridle-power.conf} --quiet";
        };
        path = lib.mkForce [ config.services.power-profiles-daemon.package ];
        # Let the regular hypridle register itself first to avoid any issues/races
        after = [ "hypridle.service" ];
      });
      assertions = [
        {
          assertion = this.hypr.hypridle-power -> config.services.power-profiles-daemon.enable;
          message = "custom.desktop.hypr.hypridle-power requires power-profiles-deamon";
        }
      ];
      # power-profiles-daemon writes its state to disk every time it changes.
      # When it changes every few seconds, that's quite a lot of data it writes;
      # amplified by filesystem commit overhead.
      fileSystems."/var/lib/power-profiles-daemon" = lib.mkIf this.hypr.hypridle-power {
        device = "tmpfs";
        fsType = "tmpfs";
        options = [
          # Just a few dozen bytes large state file
          "size=1M"
        ];
      };

      services.xserver.desktopManager.gnome.enable = this.tablet;
      environment.gnome.excludePackages = with pkgs; [
        orca
      ];

      hardware.brillo.enable = true;

      environment.systemPackages = lib.mkMerge [
        (with pkgs; [
          brightnessctl
          rofi-wayland-custom
          wev
        ])
        (lib.mkIf this.tablet (
          with pkgs;
          [
            styluslabs-write
          ]
        ))
      ];

      services.dbus.enable = true;

      services.gnome.gnome-keyring.enable = true;
      nixpkgs.overlays = [
        (final: prev: {
          # As is tradition, gnome-keyring is annoying and the only
          # upstream-intended method of starting it is explicitly gated to only
          # work in GNOME, MATE and Unity. Starting it through other means is
          # extremely annoying due to the PAM integration and whatnot. This
          # allows it to work in any desktop.
          gnome-keyring = final.runCommand "gnome-keyring-all-desktops" { } ''
            cp -rs ${prev.gnome-keyring} $out
            for file in $out/etc/xdg/autostart/*.desktop ; do
              chmod +w $(dirname $file)
              cp --remove-destination "$(readlink "$file")" "$file"
              sed -i '/OnlyShowIn/d' "$file"
            done
          '';
        })
      ];

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

      services.ddccontrol.enable = true;
      hardware.i2c.enable = true;
      hardware.i2c.group = "users";

      environment.sessionVariables.NIXOS_OZONE_WL = "1";

      services.printing.enable = true;

      programs.ausweisapp.enable = true;
      programs.ausweisapp.openFirewall = true;

      programs.appimage.enable = true;
      programs.appimage.binfmt = true;

      programs.adb.enable = true;

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

      environment.etc."wallpaper/lockscreen.svg".source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/NixOS/nixos-artwork/f07707cecfd89bc1459d5dad76a3a4c5315efba1/wallpapers/nix-wallpaper-nineish-dark-gray.svg";
        hash = "sha256-Pul1zS78O0e4IkZL9lwgPwd+3vPlwvUlt/HbGj5fi7k=";
      };

      programs.direnv.enable = true;

      programs.localsend.enable = true;
      programs.localsend.openFirewall = true;

      networking.networkmanager.enable = true;

      networking.networkmanager.logLevel = "INFO"; # Prints useful info to journalctl
      networking.networkmanager.wifi.macAddress = "stable"; # TODO what exactly does this mean?
      networking.networkmanager.wifi.scanRandMacAddress = true; # default
      networking.networkmanager.unmanaged = [
        "docker0"
        "virbr0"
        "anbox0"
      ];

      # Just utterly broken. See
      # https://github.com/NixOS/nixpkgs/issues/180175#issuecomment-1660635001
      systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;

      services.emacs.enable = true;
      # Emacs likes to get itself stuck waiting on user input or some shit on the
      # rather explicit (kill-emacs) command. Let's not tolerate that.
      systemd.user.services.emacs.serviceConfig.TimeoutStopSec = "10s";

      # No friggin 600MB mbrola!
      services.speechd.enable = false;

      # https://github.com/flatpak/xdg-desktop-portal-gtk/pull/504
      systemd.user.services.xdg-desktop-portal-gtk = {
        overrideStrategy = "asDropin";
        serviceConfig.Slice = [ "session.slice" ];
      };
      # https://github.com/dunst-project/dunst/pull/1397
      systemd.user.services.dunst = {
        overrideStrategy = "asDropin";
        serviceConfig.Slice = [ "session.slice" ];
      };
      # https://gitlab.gnome.org/GNOME/dconf/-/issues/87
      systemd.user.services.dconf = {
        overrideStrategy = "asDropin";
        serviceConfig.Slice = [ "session.slice" ];
      };

      # Makes Docker socket activated, only starting it after I use it once
      systemd.services.docker = lib.mkIf config.virtualisation.docker.enable {
        wantedBy = lib.mkForce [ ];
      };
    }
  );
}
