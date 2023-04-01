{ pkgs, config, lib, ... }:

with pkgs;

let
  # Packages to always install.
  common = [
    acpi
    aespipe
    aria2
    bash-completion
    bat
    bc
    bind
    borgbackup
    brightnessctl
    btop
    btrfs-progs
    cifs-utils
    compsize
    cryptsetup
    curl
    ddrescue
    delta
    diceware
    dos2unix
    efibootmgr
    ethtool
    exiftool
    f2fs-tools
    fd
    file
    git
    gnupg
    hdparm
    hyperfine
    iftop
    iotop
    iperf
    iw
    jq
    killall
    libarchive
    lm_sensors
    lsof
    lsscsi
    lz4
    man-pages
    mediainfo
    modemmanager
    mosh
    ncdu
    neofetch
    netcat-gnu
    nethogs
    nix-bash-completions
    nix-index
    nix-top
    nix-tree
    nixpkgs-fmt
    nixpkgs-review
    nmap
    nomacs
    ntfs3g
    onefetch
    p7zip
    pciutils
    protonvpn-cli
    pstree
    pv
    qrencode
    ranger
    ripgrep
    rsync
    screen
    smartmontools
    smem
    sshfs
    stress
    sysstat
    tigervnc
    traceroute
    tree
    unzip
    usbutils
    vim
    vmtouch
    wget
    which
    whois
    wol
    youtube-dl
    zip
    zstd
  ]
  ++ (with config.boot.kernelPackages; [
    cpupower
    perf
  ])
  ++ lib.optionals (stdenv.targetPlatform.isx86) [
    ffmpeg-full
    haskellPackages.git-annex
    shellcheck
  ]
  ++ lib.optionals (stdenv.targetPlatform.isAarch32) [
    ffmpeg
  ];

  # Packages to install if X is not enabled.
  noX = [
    emacs-nox # FIXME this needs to be handled in custom.emacs
    rxvt-unicode-unwrapped.terminfo
  ];

  # Packages to install if X is enabled.
  x = let
    obs = wrapOBS {
      plugins = with obs-studio-plugins; [
        obs-vkcapture
        obs-gstreamer
        wlrobs
      ];
    };
  in [
    BeatSaberModManager
    anki-bin
    appimage-run
    chromium
    config.custom.emacs
    direnv
    discord
    element-desktop
    firefox-pgo
    gimp
    gnome.adwaita-icon-theme # fix lutris' missing icons
    goverlay
    libreoffice
    libstrangle
    lutris
    lxrandr
    mangohud
    mlterm
    mozlz4a
    mpv
    obs
    pavucontrol
    piper
    prismlauncher
    protontricks
    pulseaudio # For pactl when pipewire is enabled
    python3
    signal-desktop
    spotify
    teamspeak_client
    tor-browser-bundle-bin
    virt-manager
    vlc
    vulkan-tools
    wineWowPackages.staging
    xclip
    xorg.xev
  ];
in
{
  nixpkgs.config.allowUnfree = true; # :(

  nixpkgs.config.packageOverrides = pkgs: {
    unstable = import <nixos-unstable> {
      config = config.nixpkgs.config; # propagate `allowUnfree`
    };
    stable = import <nixos-stable> {
      config = config.nixpkgs.config; # propagate `allowUnfree`
    };
  };

  # List of packages installed in system profile.
  environment.systemPackages = lib.mkIf config.custom.withPackages (
    # If the host config enables X, X packages are also imported
    common ++ (if config.custom.desktop.enable then x else noX)
  );
}
