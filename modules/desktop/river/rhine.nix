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
        wantedBy = [ "wayland-session@river-rhine.target" ];
        after = [ "wayland-wm@Hyprland.service" ];
        before = [ "wayland-session@river-rhine.target" ];
        partOf = [ "wayland-session@river-rhine.target" ];
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
        binPath = lib.getExe pkgs.river;
        extraArgs = [
          "-c"
          (lib.getExe pkgs.rhine)
        ];
        prettyName = "river-rhine";
      };
    };
  };
}
