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
    clang # DOOM emacs
    compsize
    cryptsetup
    curl
    ddrescue
    diceware
    fd
    file
    git
    gnupg
    gotop
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
    mimic # Mycroft's TTS
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
    nox
    ntfs3g
    pciutils
    pv
    ranger
    rclone
    ripgrep
    rsync
    rtv
    screen
    silver-searcher
    smartmontools
    stress
    sysstat
    testdisk
    traceroute
    tree
    unzip
    usbutils
    vim
    wget
    which
    whois
    wol
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
    blender
    chromium
    (emacsWithPackages [ emacsPackages.emacs-libvterm ])
    firefox-bin
    gimp
    gnome3.adwaita-icon-theme # fix lutris' missing icons
    jdk
    jetbrains.idea-community
    krita
    libreoffice
    lutris
    lxrandr
    mpv
    networkmanagerapplet
    riot-desktop
    rxvt_unicode
    signal-desktop
    steam
    sxhkd
    tigervnc
    virtmanager
    vlc
    xcape
    xclip
    xorg.xbacklight
    xorg.xev
  ];
}
