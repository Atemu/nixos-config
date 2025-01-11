{ pkgs, config, lib, ... }:

let
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

  cyme-lsusb = pkgs.writeShellApplication {
    name = "lsusb";
    text = ''
      exec ${lib.getExe pkgs.cyme} --lsusb "$@"
    '';
  };

  # Packages to always install.
  common = [
    customEmacs
    customHunspell
    cyme-lsusb
  ] ++ (with pkgs; [
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
    complete-alias
    compsize
    cryptsetup
    curl
    cyme
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
    gh
    git
    git-annex
    git-remote-gcrypt
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
    nixfmt-rfc-style
    nixpkgs-review
    nmap
    numbat
    nushell
    onefetch
    p7zip
    pciutils
    protonvpn-cli
    pstree
    pv
    qrencode
    ranger
    rclone
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
    vim
    vmtouch
    wakeonlan
    wget
    which
    whois
    wol
    yq
    yt-dlp
    ytcast
    zip
    zstd
  ]) ++ (with config.boot.kernelPackages; [
    cpupower
    perf
  ]) ++ lib.optionals pkgs.stdenv.hostPlatform.isx86 (with pkgs; [
    memtest_vulkan
  ]);

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
    lxrandr
    mlterm
    mozlz4a
    mpv
    pavucontrol
    protonvpn-gui
    pulseaudio # For pactl when pipewire is enabled
    python3
    scrcpy
    signal-desktop
    spotify
    tor-browser-bundle-bin
    xclip
    xorg.xev
  ];
in {
  options.custom.packages = {
    enable = lib.mkEnableOption "my set of system packages";

    allowedUnfree = lib.mkOption {
      description = "package names of unfree packages that are allowed";
      default = [ ];
      type = with lib.types; listOf str;
    };
  };

  config = lib.mkIf this.enable {
    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) config.custom.packages.allowedUnfree;

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
