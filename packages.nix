pkgs:

with pkgs;
{
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
  ];

  x86 = [
    ffmpeg-full
    shellcheck
  ];

  aarch32 = [
    ffmpeg
  ];

  # Packages to install if X is not enabled.
  noX = [
    emacs26-nox
    rxvt_unicode.terminfo
  ];

  # Packages to install if X is enabled.
  x = [
    android-studio
    anki
    chromium
    (emacsWithPackages [ emacsPackages.emacs-libvterm ])
    firefox-bin
    gimp
    gnome3.adwaita-icon-theme # fix lutris' missing icons
    jetbrains.idea-community
    libreoffice
    lutris
    lxrandr
    mpv
    riot-desktop
    rxvt_unicode
    signal-desktop
    steam
    steam-run
    vlc
    xclip
    xorg.xev
  ];
}
