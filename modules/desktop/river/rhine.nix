{
  config,
  lib,
  pkgs,
  utils,
  ...
}:

let
  this = config.custom.desktop.river.rhine;
  mkRhineSessionService =
    conf:
    lib.mkMerge [
      conf
      {
        wantedBy = [ "wayland-session@rhine.target" ];
        after = [ "wayland-wm@rhine.service" ];
        before = [ "wayland-session@rhine.target" ];
        partOf = [ "wayland-session@rhine.target" ];
        serviceConfig = {
          Slice = [ "session.slice" ];
          Restart = "on-failure";
        };
      }
    ];
in
{
  options.custom.desktop.river.rhine = {
    enable = lib.mkEnableOption "";
    river.package = lib.mkPackageOption pkgs "river" { };
    session.services = lib.mkOption {
      # TODO ideally this would have the systemd unit type too?
      type = utils.systemdUtils.types.services;
      default = { };
    };
  };

  config = lib.mkIf this.enable {
    programs.uwsm = {
      enable = true;
      waylandCompositors.river-rhine = {
        binPath =
          # TODO write an abstraction around this
          pkgs.writeShellScriptBin "rhine" ''
            exec ${lib.getExe this.river.package} -c "${lib.getExe config.programs.uwsm.package} finalize WAYLAND_DISPLAY" "-no-xwayland" # handled via xwayland-satellite
          ''
          |> lib.getExe;
        prettyName = "river-rhine";
      };
    };
    custom.desktop.river.rhine.session.services = {
      rhine = {
        serviceConfig = {
          ExecStart = lib.getExe pkgs.rhine;
          Environment = [ "" ]; # Don't override path!
        };
      };

      xwayland-satellite = {
        serviceConfig =
          let
            display = ":0";
          in
          {
            Type = "notify";
            ExecStart = "${lib.getExe pkgs.xwayland-satellite} ${display}";
            ExecStartPost = "systemctl --user set-environment DISPLAY=${display}";
            ExecStopPost = "systemctl --user unset-environment DISPLAY"; # Always executed!
          };

        unitConfig = {
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };

        restartIfChanged = false;
      };
      river-channel = {
        serviceConfig = {
          ExecStart =
            lib.getExe
            <| pkgs.river-channel.override {
              inherit (config.custom.desktop.keyboard.layout.packages) libxkbcommon;
            };
        };
      };
      i3bar-river = {
        # Requires the rhine "hyprland" socket
        after = [ "rhine.service" ];
        # Restarting the window manager hangs up on the socket
        partOf = [ "rhine.service" ];
      };

      hypridle = {
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
      };

      # TODO this should start on any session
      # TODO have an abstraction for graphical services
      aw-server = {
        serviceConfig = {
          ExecStart = lib.getExe pkgs.aw-server-rust;
        };
      };

      aw-wayland = mkRhineSessionService {
        serviceConfig = {
          ExecStart = lib.getExe pkgs.aw-watcher-window-wayland;
        };
        after = [ "aw-server.service" ];
        partOf = [ "aw-server.service" ];
      };
    };

    systemd.user.services =
      this.session.services
      |> lib.mapAttrs (
        name: value:
        lib.mkMerge [
          value
          {
            wantedBy = [ "wayland-session@rhine.target" ];
            after = [ "wayland-wm@rhine.service" ];
            before = [ "wayland-session@rhine.target" ];
            partOf = [ "wayland-session@rhine.target" ];
            serviceConfig = {
              Slice = [ "session.slice" ];
              Restart = "on-failure";
            };
          }
        ]
      );
  };
}
