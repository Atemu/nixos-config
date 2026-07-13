{
  config,
  lib,
  pkgs,
  utils,
  ...
}:

let
  systemd.common.settings.Manager = {
    # This configures the time after which SIGTERM will be sent aswell as the
    # time after that before SIGKILL will be sent. I don't have any sort of
    # service that needs to stop for longer than a few seconds.
    DefaultTimeoutStopSec = "10s";
    # Why TF would I want to see some free text string rather than a unique
    # identifier when debugging the system‽‽‽
    StatusUnitFormat = "name";
  };
in

{
  imports =
    [
      ./modules.nix
    ]
    ++ (
      if builtins.pathExists ./private.nix then
        [ ./private.nix ]
      else
        builtins.trace "Warning: Private data not present. Private options will use test values." [ ]
    );

  # Enable my custom modules.
  custom.enable = true;

  boot.initrd.availableKernelModules = [
    "hid_roccat_ryos" # One of my USB keyboards
    "uas" # "USB Attached SATA", needed for booting off external USB drives
  ];
  boot.initrd.supportedFilesystems = [ "vfat" ]; # For recovery purposes

  boot.kernelParams = [
    # THP transparently collapses large regions of separately allocated memory
    # into hugepages which can lead to significant performance benefits.
    # By default, it only does this for processes which explicitly ask for it,
    # this makes it do that for any process
    "transparent_hugepage=always"
  ];

  boot.blacklistedKernelModules = [
    "algif_aead" # copy.fail and upstream says it's not really maintained well
  ];

  console.earlySetup = true;

  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = lib.mapAttrs (n: v: "${v}.UTF-8") {
    LC_ADDRESS = "de_DE"; # Street names etc.
    # LC_COLLATE and LC_CTYPE are unset
    LC_IDENTIFICATION = "en_GB"; # What this custom locale generally identifies as
    LC_MEASUREMENT = "de_DE"; # I live in the rest of the world where we use sensible units.
    LC_MESSAGES = "en_GB"; # y/n in prompts
    LC_MONETARY = "en_IE"; # 1,000.00€
    LC_NAME = "en_GB"; # Mr/Mrs etc.
    LC_NUMERIC = "en_GB"; # 1,000.00
    LC_PAPER = "de_DE"; # DIN A4!
    LC_TELEPHONE = "de_DE"; # Default prefix (+49) and how telephone numbers should be formatted?
    LC_TIME = "en_DK"; # ISO 8601
  };

  console.keyMap = "us";

  time.timeZone = "Europe/Berlin";

  programs.fuse.userAllowOther = true;

  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = lib.mkDefault "client"; # May get overridden for a machine
  systemd.services.tailscaled.serviceConfig.LogLevelMax = 5; # Stop the info spam
  services.tailscale.package = pkgs.tailscale.overrideAttrs (
    {
      patches ? [ ],
      ...
    }:
    {
      patches = patches ++ [
        (pkgs.fetchpatch2 {
          url = "https://github.com/Atemu/tailscale/commit/bbce05e450ec10de80ff16125d5d8428f76ceb3b.patch";
          hash = "sha256-S71VtEIQ9d4vbOqXJ68w3HN2M/60BCBtK2uWHXVtDqQ=";
        })
      ];
      # Tests take forever. The patches may at some point also cause a failure.
      doCheck = false;
    }
  );
  # tailscale writes verbose logs to its own logfiles and then truncates them
  # all the time. This, however, causes those writes to still be committed to
  # disk every time tailscale verbosely logs something which happens every few
  # seconds. Any of these writes comes with all the overhead of bringing file
  # writes to disk while the system is supposedly idle.
  # https://github.com/tailscale/tailscale/issues/14819
  systemd.tmpfiles.settings."10-tailscaled-logspam" =
    lib.genAttrs
      [
        "/var/lib/tailscale/tailscaled.log1.txt"
        "/var/lib/tailscale/tailscaled.log2.txt"
      ]
      (n: {
        "L+" = {
          argument = "/dev/null";
        };
      });

  networking.networkmanager.unmanaged = lib.mkIf config.networking.networkmanager.enable [
    "tailscale0"
    "lo"
    "podman0"
  ];

  # Stop log spam from my SOHO router's amazingly helpful port scanning
  networking.firewall.logRefusedConnections = false;

  # The hostId is set to the first 8 chars of the sha256 of the hostName
  networking.hostId = lib.substring 0 8 (builtins.hashString "sha256" config.networking.hostName);

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    nssmdns6 = true;
    openFirewall = true;

    publish = {
      enable = true;
      domain = true;
      addresses = true;
      hinfo = true;
    };

    extraServiceFiles = {
      ssh = lib.mkIf config.services.openssh.enable "${pkgs.avahi}/etc/avahi/services/ssh.service";
    };
  };

  services.openssh.enable = lib.mkDefault true;
  services.openssh.settings.PasswordAuthentication = false;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.atemu = {
    isNormalUser = true;
    # TODO set these in the respective modules
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
      "video"
      "paperless"
      "scanner"
    ];
    shell = pkgs.bash;
    initialPassword = lib.mkIf (config.users.users.atemu.hashedPasswordFile == null) "none";
    home = lib.mkIf config.custom.fs.btrfs.newLayout "/Users/atemu";
    openssh.authorizedKeys.keys =
      let
        hostKeys = {
          HEPHAISTOS = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH3J1F+a1lSq05KPiH0gdZkx9q5w8XHfwqB3JfCzSzAV atemu@HEPHAISTOS";
          THESEUS = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIcU6XG0H5Fs0jl9mHiPWwI3BdHz4Uf9CIAc94eklV9Y atemu@THESEUS";
          PLATON = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHK/Gx95TAvE5GmEuLwWgOQpwjkWNaVavprNlFOuCjFI atemu@PLATON";
          AMONI = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO68S1T3kZl6xvzlB2O/zuG2nVv/9tnDpXZspE/xdXUn atemu@AMONI";
        };
      in
      # All keys but the host's own key
      lib.attrValues (removeAttrs hostKeys [ config.networking.hostName ]);
  };

  nix.nixPath = [
    "nixpkgs=/nix/var/nix/nixpkgs"
    "/nix/var/nix/profiles/per-user/root/channels"
  ];

  systemd.services.nix-daemon.environment.TMPDIR = "/var/tmp/";

  nix = {
    package = config.custom.packages.lix.packages.lix;

    settings = {
      experimental-features = [
        "nix-command"
        "flakes" # Ugh
        "pipe-operator"
        "lix-custom-sub-commands"
      ];
      # Don't stop debugger on caught exceptions
      ignore-try = true;
      # If you're not receiving anything for 20s, just retry
      stalled-download-timeout = 20;
      # I do not care.
      warn-dirty = false;
      # Builders should substitute from cache.nixos.org
      builders-use-substitutes = true;
      # WTF no‽
      accept-flake-config = false;
      # nom-lite
      log-format = "multiline-with-logs";
      # I have log lines on; I already see the logs. Also, just the last 25 are
      # usually useless. I'd rather just `nix log`.
      log-lines = 0;
      # It's like 2× with just btrfs zstd compression and at e5 Bytes I'd rather
      # not have to muck with bzip2
      build-compress-log = false;

      # Automatically enables signing of all built store paths
      secret-key-files = config.custom.secrets.store-path-signing.path;
      trusted-public-keys = [
        # All machines trust each others' build outputs
        "THESEUS:N571Rz/bXMDWTmRefYb1JGz0r/gAugFAndVIn8/+bc4="
        "SOTERIA:FPjTyCztUrddjda9eTPyOSetyWxiSOPDDXNRtWMX9v4="
        # TODO add the missing ones
      ];
      require-sigs = true;
    };

    daemonCPUSchedPolicy = "batch";
    daemonIOSchedClass = "idle";
    # maybe set to batch on non-desktop
  };
  custom.secrets.store-path-signing = { };

  # Use bfq iosched for everything except NVMe and loop devs
  hardware.block = {
    defaultScheduler = "bfq";
    defaultSchedulerRotational = "bfq";
    scheduler = {
      # AFAIK NVME drives are so fast that fancy scheduling might hurt
      # performance. Use the least fancy scheduling that still supports IO
      # priorities.
      "nvme*" = "mq-deadline";
      # I probably don't want a nested queue?
      "loop*" = "none";
    };
  };

  # Don't need it and it takes quite a while to build.
  documentation.nixos.enable = false;

  programs.command-not-found.dbPath = "/nix/var/nix/programs.sqlite";

  # I don't want random systemPackages' autostart units, TYVM.
  xdg.autostart.enable = lib.mkForce false;

  systemd.settings = systemd.common.settings;
  # Same for user
  # TODO in 26.11, this is simply settings too
  systemd.user.extraConfig = utils.systemdUtils.lib.settingsToSections systemd.common.settings;
  # This overrides the default with 120s by default. Stop it.
  systemd.services."user@".serviceConfig.TimeoutStopSec =
    config.systemd.settings.Manager.DefaultTimeoutStopSec;

  # FIXME setting sys values like this should be a module; probably using udev instead
  systemd.tmpfiles.rules = [
    # Congestion threshold is set incredibly low by default causing bcache to
    # have nearly no effect.
    "w /sys/fs/bcache/*/congested_read_threshold_us  - - - - 20000" # default: 2000
    "w /sys/fs/bcache/*/congested_write_threshold_us - - - - 20000" # default: 20000
    # If you're handling large chunks, you might as well have a sequential workload.
    # TODO I could not find numbers on this online, benchmark this!
    "w /sys/block/bcache*/bcache/sequential_cutoff - - - - 131071" # 128KiB - 1B, defaults to 4MiB
  ];

  boot.kernel.sysctl = {
    # Prefer caching directory and inode info over inode content as querying
    # metadata requires random IO and it's usually tiny.
    # TODO test which value is actually appropriate here; this is just a guess
    "vm.vfs_cache_pressure" = 30;
  };

  custom.replication.mapping = {
    THESEUS = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgAF6PCcdjAFmimGMZp+qNUTqjYyQK4zY5QJBab1TiR root@THESEUS";
    };
  };

  networking.hosts."23.137.248.133" = [
    # archive.today and friends play dirty with DNS
    "archive.today"
    "archive.fo"
    "archive.is"
    "archive.li"
    "archive.md"
    "archive.ph"
    "archive.vn"
  ];
}
