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
  };

  config = lib.mkIf this.enable {
    programs.uwsm = {
      enable = true;
      waylandCompositors.river-rhine = {
        binPath =
          # TODO write an abstraction around this
          pkgs.writeShellScriptBin "rhine" ''
            exec ${lib.getExe pkgs.river} "$@"
          ''
          |> lib.getExe;
        extraArgs = [
          "-c"
          (lib.getExe pkgs.rhine)
          "-no-xwayland" # handled via xwayland-satellite
        ];
        prettyName = "river-rhine";
      };
    };

    systemd.user.services.river-channel = mkRhineSessionService {
      serviceConfig = {
        ExecStart = lib.getExe pkgs.river-channel;
      };
    };
  };
}
