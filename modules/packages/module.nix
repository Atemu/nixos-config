{ pkgs, config, lib, ... }:

with pkgs;

let
  inherit (lib) optionals mkIf mkEnableOption mkOption getName versionAtLeast;
  inherit (lib.types) bool listOf str;
  inherit (lib.trivial) release;

  # Packages to always install.
  common = [
    acpi
    aria2
    bash-completion
    bat
    bc
    bind
    borgbackup
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
    fd
    ffmpeg
    file
    git
    git-annex
    gnupg
    hdparm
    hyperfine
    iftop
    iotop
    iperf
    jc
    jq
    killall
    libarchive
    lm_sensors
    lsof
    lz4
    man-pages
    mediainfo
    mosh
    ncdu
    neofetch
    netcat-gnu
    nethogs
    nix-bash-completions
    nix-index
    nix-init
    nix-tree
    nixpkgs-fmt
    nixpkgs-review
    nmap
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
  ] ++ (with config.boot.kernelPackages; [
    cpupower
    perf
  ]) ++ optionals (versionAtLeast release "23.11") [
    numbat
  ];

  # Packages to install if X is not enabled.
  noX = [
    emacs-nox # FIXME this needs to be handled in custom.emacs
    rxvt-unicode-unwrapped.terminfo
  ];

  # Packages to install if X is enabled.
  x = [
    anki
    appimage-run
    config.custom.emacs
    direnv
    element-desktop
    firefox-pgo
    gimp
    lxrandr
    mlterm
    mozlz4a
    mpv
    nomacs
    pavucontrol
    pulseaudio # For pactl when pipewire is enabled
    python3
    signal-desktop
    spotify
    tigervnc
    tor-browser-bundle-bin
    virt-manager
    vlc
    xclip
    xorg.xev
  ];
in {
  options.custom.packages = {
    enable = mkEnableOption "my set of system packages" // mkOption {
      default = true;
    };

    allowedUnfree = lib.mkOption {
      description = "package names of unfree packages that are allowed";
      default = [ ];
      type = listOf str;
    };
  };

  config = {
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (getName pkg) config.custom.packages.allowedUnfree;

    # :(
    custom.packages.allowedUnfree = [
      "spotify"
    ];

    # List of packages installed in system profile.
    environment.systemPackages = mkIf config.custom.packages.enable (
      # If the host config enables X, X packages are also imported
      common ++ (if config.custom.desktop.enable then x else noX)
    );
  };
}
