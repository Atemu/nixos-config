{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf optionals;
  this = config.custom.gaming;
in

{
  options.custom.gaming = {
    enable = mkEnableOption "my custom gaming setup";
    amdgpu = mkEnableOption "my custom AMDGPU setup" // {
      default = true;
    };
  };

  config = mkIf this.enable {
    programs.steam.enable = true;
    programs.steam.extraCompatPackages = [ pkgs.proton-ge-bin ];
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
      yuzu-ea
    ] ++ optionals this.amdgpu [
      lact
      radeontop
      rocmPackages.rocm-smi
      umr
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

    services.xserver.videoDrivers = mkIf this.amdgpu [ "amdgpu" ];
    services.xserver.deviceSection = mkIf this.amdgpu ''
      Option "TearFree" "False"
      Option "VariableRefresh" "True"
    '';
    boot.initrd.kernelModules = mkIf this.amdgpu [ "amdgpu" ];

    custom.lact.enable = this.amdgpu;

    hardware.steam-hardware.enable = true;

    services.ratbagd.enable = true;
  };
}
