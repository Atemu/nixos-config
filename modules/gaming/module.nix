{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf optionals;
  this = config.custom.gaming;
in

{
  options.custom.gaming = {
    enable = mkEnableOption "my custom gaming setup";
    amdgpu = mkEnableOption "my custom AMDGPU setup";
  };

  # Sink this option when under 24.05
  options.programs.steam = lib.optionalAttrs (lib.versionOlder lib.trivial.release "24.05") {
    extraCompatPackages = lib.mkSinkUndeclaredOptions { };
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
    environment.systemPackages =
      let
        general = with pkgs; [
          BeatSaberModManager
          discord
          gnome.adwaita-icon-theme # fix lutris' missing icons
          goverlay
          libstrangle
          lutris
          mangohud
          piper
          prismlauncher
          protontricks
          teamspeak_client
          vulkan-tools
          wineWowPackages.staging
        ];
        amdgpu = with pkgs; [
          lact
          radeontop
          rocmPackages.rocm-smi
          umr
        ];

        obs = pkgs.wrapOBS {
          plugins = with pkgs.obs-studio-plugins; [
            obs-vkcapture
            obs-gstreamer
            wlrobs
          ];
        };
      in
      general
      ++ optionals this.amdgpu amdgpu
        # Was removed upstream but I still have it in my Nixpkgs fork. This is a
        # little hack for making it possible to at least eval the rest of my
        # config with nixpkgs trees that do not have yuzu.
      ++ lib.optional (builtins.tryEval pkgs.yuzu-ea).success pkgs.yuzu-ea
      ++ [
        obs
      ];
    custom.packages.allowedUnfree = [
      "steam"
      "steam-original"
      "steam-run"
      "discord"
      "teamspeak-client"
    ];

    programs.gamemode.enable = true;

    boot.kernel.sysctl = {
      # SteamOS/Fedora default, can help with performance.
      "vm.max_map_count" = 2147483642;

      # Not part of my threat model and I'd rather not have performance tank in
      # poorly coded games.
      "kernel.split_lock_mitigate" = 0;
    };

    services.xserver.deviceSection = mkIf this.amdgpu ''
      Option "VariableRefresh" "True"
    '';
    boot.initrd.kernelModules = mkIf this.amdgpu [ "amdgpu" ];

    custom.lact.enable = this.amdgpu;

    hardware.steam-hardware.enable = true;

    services.ratbagd.enable = true;
  };
}
