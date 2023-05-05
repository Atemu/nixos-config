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
    };
    extraLibraries = p: with p; [
      atk
      udev
    ];
  };

  environment.systempackages = with pkgs; [
    BeatSaberModManager
    gnome.adwaita-icon-theme # fix lutris' missing icons
    goverlay
    libstrangle
    lutris
    mangohud
    obs
    piper
    prismlauncher
    protontricks
    vulkan-tools
    wineWowPackages.staging
  ];

  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;

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

  system.stateVersion = "20.09";
}
