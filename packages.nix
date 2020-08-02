{ pkgs, config, lib, ... }:

with pkgs;

let
  # Packages to always install.
  common = [
    acpi
    aespipe
    bash-completion
    bc
    bind
    brightnessctl
    btrfs-progs
    cifs-utils
    compsize
    cryptsetup
    curl
    ddrescue
    diceware
    fd
    file
    git
    gnupg
    hdparm
    iftop
    iotop
    iperf
    iw
    jq
    killall
    libarchive
    linuxPackages.cpupower
    linuxPackages.perf
    lm_sensors
    lsof
    lz4
    man-pages
    mediainfo
    modemmanager
    mosh
    ncdu
    neofetch
    netcat-gnu
    nix-bash-completions
    nix-index
    nix-top
    nixpkgs-review
    nmap
    ntfs3g
    pciutils
    pv
    ranger
    ripgrep
    rsync
    screen
    smartmontools
    stress
    sysstat
    traceroute
    tree
    unzip
    usbutils
    vim
    wget
    which
    whois
    wol
    youtube-dl
    zip
    zstd
  ]
  ++ lib.optionals (stdenv.targetPlatform.isx86) [
    ffmpeg-full
    shellcheck
  ]
  ++ lib.optionals (stdenv.targetPlatform.isAarch32) [
    ffmpeg
  ];

  # Packages to install if X is not enabled.
  noX = [
    emacs26-nox
    rxvt_unicode.terminfo
  ];

  emacs-vterm = (emacsWithPackages [ emacsPackages.vterm ]);

  # Packages to install if X is enabled.
  x = [
    android-studio
    anki
    chromium
    emacs-vterm
    firefox-bin
    gimp
    gnome3.adwaita-icon-theme # fix lutris' missing icons
    jetbrains.idea-community
    libreoffice
    lutris
    lxrandr
    mozlz4a
    mpv
    element-desktop
    rxvt_unicode
    signal-desktop
    steam
    steam-run
    torbrowser
    vlc
    xclip
    xorg.xev
  ];
in
{
  # List of packages installed in system profile.
  # If the host config enables X, X packages are also imported
  environment.systemPackages = common ++ (if config.services.xserver.enable then x else noX);
}
