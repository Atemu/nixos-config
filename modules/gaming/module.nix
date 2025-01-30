{
  config,
  lib,
  pkgs,
  ...
}:

let
  this = config.custom.gaming;
in

{
  options.custom.gaming = {
    enable = lib.mkEnableOption "my custom gaming setup";
    amdgpu = lib.mkEnableOption "my custom AMDGPU setup";

    steamvr.unprivilegedHighPriorityQueue = lib.mkEnableOption ''
      whether to allow any unprivileged process to create a high priority queue.
      This is a workaround required for SteamVR's asynchronous projection to
      function properly within the Nix Steam FHS container.

      Note that enabling this has security implications as it'd allow any
      process to deny service of the system (DOS). This should however not be
      a critical vulnerability on a typical single-user desktop machine.
    '';
  };

  config = lib.mkIf this.enable (
    lib.optionalAttrs (lib.versionAtLeast lib.trivial.release "24.11") {
      programs.steam.enable = true;
      programs.steam.extraCompatPackages = with pkgs; [
        proton-ge-bin
        steamtinkerlaunch
      ];
      programs.steam.package = pkgs.steam-small.override {
        extraEnv = {
          MANGOHUD = true;
          OBS_VKCAPTURE = true;
          RADV_TEX_ANISO = 16;
          DXVK_HUD = "compiler";
          PULSE_SINK = "game_sink"; # For separate capture
        };
        extraLibraries =
          p: with p; [
            atk
            dbus
            udev
          ];
        # My games library is mounted at /Volumes/Games/ and Steam's state is also
        # stored there. It stores all of my Games' state too in fact. Ensure the
        # locations exist and bind-mount the real places where Steam expects them.
        extraPreBwrapCmds = ''
          mkdir -p $HOME/.local/share/Steam/ /Volumes/Games/Steam/
        '';
        extraBwrapArgs = [
          "--bind /Volumes/Games/Steam/ $HOME/.local/share/Steam/"
          "--bind /Volumes/Games/ /Volumes/Games/Steam/steamapps/common/"
        ];
      };
      programs.steam.protontricks.enable = true;
      programs.steam.localNetworkGameTransfers.openFirewall = true;

      # TODO extract into a custom.gaming option
      environment.systemPackages =
        let
          general = with pkgs; [
            BeatSaberModManager
            discord
            mangohud
            piper
            steamtinkerlaunch
            teamspeak_client
            vulkan-tools
          ];
          amdgpu = with pkgs; [
            lact
            radeontop
            umr
          ];

          prismlauncher = pkgs.prismlauncher.override {
            # I don't need 3 JDKs.
            jdks = [ pkgs.jdk17 ];
          };
        in
        lib.mkMerge [
          general
          (lib.mkIf this.amdgpu amdgpu)
          # Was removed upstream but I still have it in my Nixpkgs fork. This is a
          # little hack for making it possible to at least eval the rest of my
          # config with nixpkgs trees that do not have yuzu.
          # (lib.mkIf (pkgs ? yuzu-ea && (builtins.tryEval pkgs.yuzu-ea).success) [ pkgs.yuzu-ea ])
          [ prismlauncher ]
        ];
      custom.packages.allowedUnfree = [
        "steam"
        "steam-unwrapped"
        "discord"
        "teamspeak3"
      ];
      # BSMM depends on old SDKs...
      # https://github.com/NixOS/nixpkgs/pull/339370
      nixpkgs.config.permittedInsecurePackages = [
        "dotnet-runtime-wrapped-6.0.36"
        "dotnet-runtime-wrapped-7.0.20"
        "dotnet-runtime-7.0.20"
        "dotnet-core-combined"
        "dotnet-sdk-6.0.428"
        "dotnet-sdk-7.0.410"
        "dotnet-sdk-wrapped-6.0.428"
        "dotnet-sdk-wrapped-7.0.410"
      ];
      programs.obs-studio.enable = true;
      programs.obs-studio.plugins = with pkgs.obs-studio-plugins; [
        obs-vkcapture
        obs-gstreamer
        wlrobs
      ];

      programs.gamemode.enable = true;

      boot.kernel.sysctl = {
        # SteamOS/Fedora default, can help with performance.
        "vm.max_map_count" = 2147483642;

        # Not part of my threat model and I'd rather not have performance tank in
        # poorly coded games.
        "kernel.split_lock_mitigate" = 0;
      };

      services.xserver.deviceSection = lib.mkIf this.amdgpu ''
        Option "VariableRefresh" "True"
      '';
      boot.initrd.kernelModules = lib.mkIf this.amdgpu [ "amdgpu" ];

      custom.amdgpu.kernelModule.patches = lib.mkIf this.steamvr.unprivilegedHighPriorityQueue [
        (pkgs.fetchpatch2 {
          url = "https://github.com/Frogging-Family/community-patches/raw/a6a468420c0df18d51342ac6864ecd3f99f7011e/linux61-tkg/cap_sys_nice_begone.mypatch";
          hash = "sha256-1wUIeBrUfmRSADH963Ax/kXgm9x7ea6K6hQ+bStniIY=";
        })
      ];

      custom.lact.enable = this.amdgpu;

      hardware.steam-hardware.enable = true;

      services.ratbagd.enable = true;
    }
  );
}
