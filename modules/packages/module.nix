{ pkgs, config, lib, ... }:

let
  inherit (lib) optionals mkIf mkEnableOption mkOption getName versionAtLeast;
  inherit (lib.types) bool listOf str;
  inherit (lib.trivial) release;

  this = config.custom.packages;

  # Packages to always install.
  common = with pkgs; [
    acpi
    aria2
    bash-completion
    bat
    bc
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
    ldns # drill
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
    nix-output-monitor
    nix-tree
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
  ] ++ optionals (versionAtLeast release "24.05") [
    nixfmt-rfc-style
  ];

  # Packages to install if X is not enabled.
  noX = with pkgs; [
    emacs-nox # FIXME this needs to be handled in custom.emacs
    rxvt-unicode-unwrapped.terminfo
  ];

  # Packages to install if X is enabled.
  x = with pkgs; [
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
    enable = mkEnableOption "my set of system packages";

    allowedUnfree = lib.mkOption {
      description = "package names of unfree packages that are allowed";
      default = [ ];
      type = listOf str;
    };
  };

  config = mkIf this.enable {
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (getName pkg) config.custom.packages.allowedUnfree;

    # :(
    custom.packages.allowedUnfree = [
      "spotify"
    ];

    # List of packages installed in system profile.
    environment.systemPackages = (
      # If the host config enables X, X packages are also imported
      common ++ (if config.custom.desktop.enable then x else noX)
    );
  };
}
