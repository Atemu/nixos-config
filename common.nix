{ config, lib, pkgs, ... }:

let
  nixfiles = "/nix/var/nix/nixfiles";

  inherit (lib) attrValues substring;
in

{
  imports = [
    ./modules.nix
  ] ++ (
    if builtins.pathExists ./secrets.nix
    then [ ./secrets.nix ]
    else builtins.trace "Warning: Secrets not present. Options that use eval secrets will use test values." [ ]
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
    LC_PAPER = "de_DE";# DIN A4!
    LC_TELEPHONE = "de_DE"; # Default prefix (+49) and how telephone numbers should be formatted?
    LC_TIME = "en_DK"; # ISO 8601
  };

  console.keyMap = "us";

  time.timeZone = "Europe/Berlin";

  programs.screen.screenrc = "startup_message off";

  programs.direnv.enable = true;

  services.lorri.enable = true; # perhaps desktop-only?

  programs.fuse.userAllowOther = true;

  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = lib.mkDefault "client"; # May get overridden for a machine
  systemd.services.tailscaled.serviceConfig.LogLevelMax = 5; # Stop the info spam
  services.tailscale.package = pkgs.tailscale.overrideAttrs (prevAttrs: {
    patches = prevAttrs.patches or [ ] ++ [
      (pkgs.fetchpatch2 {
        url = "https://github.com/Atemu/tailscale/commit/ecaa38f85750adab9f51a5353766f2b135cd017a.patch";
        hash = "sha256-yJ+mbBupLp4sXrgFS5yQaKNynZ87tnnwhreQ88HazVM=";
      })
    ];
  });

  # FIXME https://github.com/NixOS/nixpkgs/issues/180175#issuecomment-1655787774
  networking.networkmanager.unmanaged = [ "tailscale0" "lo" ];

  # Stop log spam from my SOHO router's amazingly helpful port scanning
  networking.firewall.logRefusedConnections = false;

  # The hostId is set to the first 8 chars of the sha256 of the hostName
  networking.hostId = substring 0 8 (builtins.hashString "sha256" config.networking.hostName);

  services.avahi = {
    enable = true;
    nssmdns = true;

    publish = {
      enable = true;
      domain = true;
      addresses = true;
      hinfo = true;
    };

    extraServiceFiles = {
      ssh = lib.mkIf config.services.sshd.enable "${pkgs.avahi}/etc/avahi/services/ssh.service";
    };
  };

  services.openssh.settings.PasswordAuthentication = false;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.atemu = {
    isNormalUser = true;
    # TODO set these in the respective modules
    extraGroups = [ "wheel" "networkmanager" "docker" "video" "libvirtd" "corectrl" "paperless" "scanner" ];
    shell = pkgs.bash;
    initialPassword = "none";
    home = lib.mkIf config.custom.fs.btrfs.newLayout "/Users/atemu";
    openssh.authorizedKeys.keys = let
      hostKeys = {
        HEPHAISTOS = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH3J1F+a1lSq05KPiH0gdZkx9q5w8XHfwqB3JfCzSzAV atemu@HEPHAISTOS";
        LYKOURGOS = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIcU6XG0H5Fs0jl9mHiPWwI3BdHz4Uf9CIAc94eklV9Y atemu@LYKOURGOS";
        PLATON = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHK/Gx95TAvE5GmEuLwWgOQpwjkWNaVavprNlFOuCjFI atemu@PLATON";
      };
      # All keys but the host's own key
    in attrValues (removeAttrs hostKeys [ config.networking.hostName ]);
  };

  nix.nixPath = [
    "nixpkgs=${nixfiles}/nixpkgs"
    "nixos-config=${nixfiles}/nixos-config"
    "/nix/var/nix/profiles/per-user/root/channels"
  ];

  systemd.services.nix-daemon.environment.TMPDIR = "/var/tmp/";

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    settings = {
      # Would complicates copying between hosts.
      # FIXME: Yes this is a security issue
      require-sigs = false;
      # Don't stop debugger on caught exceptions
      ignore-try = true;
      # If you're not receiving anything for 20s, just retry
      stalled-download-timeout = 20;
      # I do not care.
      warn-dirty = false;
    };

    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
    # maybe set to batch on non-desktop
  };

  # Don't need it and it takes quite a while to build.
  documentation.nixos.enable = false;

  programs.command-not-found.dbPath = "/nix/var/nix/programs.sqlite";

  # Makes Docker socket activated, only starting it after I use it once
  systemd.services.docker.wantedBy = lib.mkIf config.virtualisation.docker.enable (lib.mkForce [ ]);

  # This configures the time after which SIGTERM will be sent aswell as the time
  # after that before SIGKILL will be sent.
  # I don't have any sort of service that needs to stop for longer than a few seconds.
  systemd.extraConfig = ''
    DefaultTimeoutStopSec=30s
  '';

  systemd.tmpfiles.rules = [
    # Congestion threshold is set incredibly low by default causing bcache to
    # have nearly no effect.
    "w /sys/fs/bcache/*/congested_read_threshold_us  - - - - 20000" # default: 2000
    "w /sys/fs/bcache/*/congested_write_threshold_us - - - - 20000" # default: 20000
  ];

  boot.kernel.sysctl = {
    # Prefer caching directory and inode info over inode content as querying
    # metadata requires random IO and it's usually tiny.
    # TODO test which value is actually appropriate here; this is just a guess
    "vm.vfs_cache_pressure" = 30;
  };

  networking.hosts."23.137.248.133" = [
    # archive.today and friends play dirty with DNS
    "archive.today" "archive.fo" "archive.is" "archive.li" "archive.md" "archive.ph" "archive.vn"
  ];
}
