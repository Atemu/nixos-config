{ config, lib, pkgs, ... }:

let
  nixos-config = "/nix/var/nix/nixos-config";
  nixpkgs = "/nix/var/nix/nixpkgs";
in

{
  imports = [
    ./btrbk.nix
    ./btrfs.nix
    ./custom.nix
    ./desktop.nix
    ./dnscrypt.nix
    ./fs.nix
    ./lib.nix
    ./luks.nix
    ./overlays.nix
    ./packages.nix
    ./vm.nix
    ./zfs.nix
    ./zram.nix
  ];

  boot.loader.timeout = 1;

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

  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  time.timeZone = "Europe/Berlin";

  programs.screen.screenrc = "startup_message off";

  programs.fuse.userAllowOther = true;

  services.tailscale.enable = true;
  # Required for exit nodes
  # TODO only allow on servers/some machines?
  networking.firewall.checkReversePath = "loose";

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


  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.atemu = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" "video" "libvirtd" "corectrl" ];
    shell = pkgs.bash;
    initialPassword = "none";
    home = lib.mkIf config.custom.fs.btrfs.newLayout "/Users/atemu";
  };

  nix.nixPath = [
    "nixpkgs=${nixpkgs}"
    "nixos-config=${nixos-config}"
    "nixos=${nixpkgs}"
    "/nix/var/nix/profiles/per-user/root/channels"
  ];
  environment.variables.NIXOS_CONFIG_DIR = "${nixos-config}";

  systemd.services.nix-daemon.environment.TMPDIR = "/var/tmp/";

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    # Because of my special nix setup, the `nix` command is actually 2.3 eventhough the package is newer
    # Disable checks
    checkConfig = false;

    settings.require-sigs = false;

    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
    # maybe set to batch on non-desktop

    package = pkgs.customNix;
  };

  # Don't need it and it takes quite a while to build.
  documentation.nixos.enable = false;

  programs.command-not-found.dbPath = "/nix/var/nix/programs.sqlite";

  # Makes Docker socket activated, only starting it after I use it once
  systemd.services.docker.wantedBy = lib.mkIf config.virtualisation.docker.enable (lib.mkForce [ ]);
}
