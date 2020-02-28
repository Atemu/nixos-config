pkgs: with pkgs;
  {
    # Packages to always install.
    common = [
      acpi
      aespipe
      bash-completion
      bc
      bind
      btrfs-progs
      cifs-utils
      clang # DOOM emacs
      compsize
      cryptsetup
      curl
      ddrescue
      diceware
      fd
      ffmpeg-full
      ffsend
      file
      git
      gnupg
      gotop
      hdparm
      iftop
      iotop
      iperf
      iw
      killall
      libarchive
      linuxPackages.cpupower
      linuxPackages.perf
      lm_sensors
      lsof
      lz4
      man-pages
      mimic # Mycroft's TTS
      modemmanager
      mosh
      ncdu
      neofetch
      nix-bash-completions
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
      smartmontools
      stress
      sysstat
      testdisk-photorec
      thefuck
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

    # Packages to install if X is not enabled.
    noX = [
      emacs26-nox
      rxvt_unicode.terminfo
      signal-cli
    ];

    # Packages to install if X is enabled.
    x = [
      android-studio
      anki
      blender
      chromium
      dmenu
      emacs
      firefox-bin
      geogebra
      gimp
      gnome3.adwaita-icon-theme # fix for lutris' icons FIXME 
      jdk
      jetbrains.idea-community
      krita
      libreoffice
      lutris
      lxrandr
      modem-manager-gui
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
