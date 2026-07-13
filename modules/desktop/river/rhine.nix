{
  config,
  lib,
  pkgs,
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
        };
      }
    ];
in
{
  options.custom.desktop.river.rhine = {
    enable = lib.mkEnableOption "";
    river.package =
      (lib.mkPackageOption pkgs "river" { })
      // lib.mkOption {
        default = pkgs.river.override {
          inherit (config.custom.desktop.keyboard.layout.packages) libxkbcommon;
        };
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
    systemd.user.services.rhine = mkRhineSessionService {
      serviceConfig = {
        ExecStart = lib.getExe pkgs.rhine;
        Environment = [ "" ]; # Don't override path!
      };
    };

    systemd.user.services.xwayland-satellite = mkRhineSessionService {
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
    systemd.user.services.river-channel = mkRhineSessionService {
      serviceConfig = {
        ExecStart = lib.getExe pkgs.river-channel;
      };
    };
  };
}
