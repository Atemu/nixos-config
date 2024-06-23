{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf optionals;
  this = config.custom.gaming;
in

{
  options.custom.gaming = {
    enable = mkEnableOption "my custom gaming setup";
    amdgpu = mkEnableOption "my custom AMDGPU setup";

    steamvr.unprivilegedHighPriorityQueue = mkEnableOption ''
      whether to allow any unprivileged process to create a high priority queue.
      This is a workaround required for SteamVR's asynchronous projection to
      function properly within the Nix Steam FHS container.

      Note that enabling this has security implications as it'd allow any
      process to deny service of the system (DOS). This should however not be
      a critical vulnerability on a typical single-user desktop machine.
    '';
  };

  config = mkIf this.enable (lib.optionalAttrs (lib.versionAtLeast lib.trivial.release "24.11") {
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
      # My games library is mounted at /Volumes/Games/. Starting SteamVR with it
      # sylinked to steamapps/common causes steamwebhelper to crash continually
      # while SteamVR is running. Interestingly, this does not happen when the
      # symlink target is /tmp and a few other specific locations. I guess my
      # library is at "/tmp/Games" now.
      extraBwrapArgs = [
        "--bind /Volumes/Games/ /tmp/Games/"
      ];
    };
    programs.steam.protontricks.enable = true;

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

    custom.amdgpu.kernelModule.patches = [
      (pkgs.fetchpatch2 {
        url = "https://github.com/Frogging-Family/community-patches/raw/a6a468420c0df18d51342ac6864ecd3f99f7011e/linux61-tkg/cap_sys_nice_begone.mypatch";
        hash = "sha256-1wUIeBrUfmRSADH963Ax/kXgm9x7ea6K6hQ+bStniIY=";
      })
    ];

    custom.lact.enable = this.amdgpu;

    hardware.steam-hardware.enable = true;

    services.ratbagd.enable = true;
  });
}
