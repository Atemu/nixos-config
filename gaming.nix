{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf;
  this = config.custom.gaming;
in

{
  options.custom.gaming = {
    enable = mkEnableOption "my custom gaming setup";
  };

  config = mkIf this.enable {
    programs.steam.enable = true;
    programs.steam.package = pkgs.steam-small.override {
      extraEnv = {
        MANGOHUD = true;
        OBS_VKCAPTURE = true;
        RADV_TEX_ANISO = 16;
        DXVK_HUD = "compiler";
        PULSE_SINK = "game_sink"; # For separate capture
      };
      extraLibraries = p: with p; [
        atk
        dbus
        udev
      ];
    };

    # TODO extract into a custom.gaming option
    environment.systemPackages = with pkgs; let
      obs = wrapOBS {
        plugins = with obs-studio-plugins; [
          obs-vkcapture
          obs-gstreamer
          wlrobs
        ];
      };
    in [
      # Gaming
      BeatSaberModManager
      discord
      gnome.adwaita-icon-theme # fix lutris' missing icons
      goverlay
      libstrangle
      lutris
      mangohud
      obs
      piper
      prismlauncher
      protontricks
      teamspeak_client
      vulkan-tools
      wineWowPackages.staging
    ];
    custom.packages.allowedUnfree = [
      "steam"
      "steam-original"
      "steam-run"
      "discord"
      "teamspeak-client"
    ];

    boot.kernel.sysctl = {
      # SteamOS/Fedora default, can help with performance.
      "vm.max_map_count" = 2147483642;
    };

    services.xserver.videoDrivers = [ "amdgpu" ];
    services.xserver.deviceSection = ''
      Option "TearFree" "False"
      Option "VariableRefresh" "True"
    '';

    programs.corectrl.enable = true;

    hardware.steam-hardware.enable = true;

    services.ratbagd.enable = true;
  };
}
