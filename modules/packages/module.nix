{ pkgs, config, lib, ... }:

let
  inherit (lib) optionals mkIf mkEnableOption getName versionAtLeast;
  inherit (lib.types) listOf str;
  inherit (lib.trivial) release;

  this = config.custom.packages;

  customEmacs = config.services.emacs.package;

  customHunspell = pkgs.hunspellWithDicts (
    with pkgs.hunspellDicts;
    [
      (en_GB-large.overrideAttrs (prev: {
        # Make dict able to detect contractions (I've, doesn't etc.) as words
        postInstall = prev.postInstall or "" + ''
          substituteInPlace $out/share/hunspell/en_GB.aff --replace "WORDCHARS 0123456789" "WORDCHARS 0123456789'"
        '';
      }))
      de_DE
    ]
  );

  # Packages to always install.
  common = with pkgs; [
    acpi
    aria2
    bash-completion
    bat
    bc
    borgbackup
    btdu
    btop
    btrfs-progs
    cifs-utils
    colmena
    compsize
    cryptsetup
    curl
    customEmacs
    customHunspell
    ddrescue
    delta
    diceware
    dos2unix
    duf
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
    nix-diff
    nix-index
    nix-init
    nix-output-monitor
    nix-tree
    nixd
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
    systemctl-tui
    tmux # This should be configured via the module instead
    traceroute
    tree
    unzip
    usbutils
    vim
    vmtouch
    wakeonlan
    wget
    which
    whois
    wol
    youtube-dl
    yq
    ytcast
    zip
    zstd
  ] ++ (with config.boot.kernelPackages; [
    cpupower
    perf
  ]) ++ optionals (versionAtLeast release "23.11") [
    numbat
  ] ++ optionals (versionAtLeast release "24.05") [
    memtest_vulkan
    nixfmt-rfc-style
  ];

  # Packages to install if X is not enabled.
  noX = with pkgs; [
    rxvt-unicode-unwrapped.terminfo
  ];

  # Packages to install if X is enabled.
  x = with pkgs; let
    customFirefox = firefox-pgo.override (prev: {
      cfg = prev.cfg or { } // {
        # No 700MiB mbrola-voices in my closure please
        speechSynthesisSupport = false;
      };
    });
  in [
    customFirefox
    direnv
    element-desktop
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
