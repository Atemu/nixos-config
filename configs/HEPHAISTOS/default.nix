{ config, pkgs, lib, ... }:

{
  imports = [
    ../../common.nix

    ./storage.nix

    ../../hardware/B550.nix
  ];

  custom.hostName = "HEPHAISTOS";

  custom.desktop.enable = true;

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

  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;

  boot.kernel.sysctl = {
    # SteamOS/Fedora default, can help with performance.
    "vm.max_map_count" = 2147483642;
  };

  services.xserver.videoDrivers = [ "amdgpu" ];
  services.xserver.deviceSection = ''
    Option "TearFree" "False"
    Option "VariableRefresh" "True"
  '';

  services.sshd.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    qemu.ovmf.enable = true;
    qemu.runAsRoot = false;
    qemu.package = pkgs.qemu_kvm; # Closure size; I don't need other µarchs
  };
  # Libvirt takes forever to start, socket activate it when I actually need it
  systemd.services.libvirtd.wantedBy = [ ];
  # Don't need this feature.
  systemd.services.libvirt-guests.wantedBy = lib.mkForce [ ];

  virtualisation.docker.enable = true;

  programs.adb.enable = true;

  custom.dnscrypt.enable = true;

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

  system.stateVersion = "20.09";
}
