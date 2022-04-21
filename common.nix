{ config, lib, pkgs, ... }:

let
  nixos-config = "/nix/var/nix/nixos-config";
  nixpkgs = "/nix/var/nix/nixpkgs";
in

{
  imports = [
    ./btrfs.nix
    ./custom.nix
    ./desktop.nix
    ./dnscrypt.nix
    ./fs.nix
    ./lib.nix
    ./overlays.nix
    ./packages.nix
    ./vm.nix
    ./zfs.nix
    ./zram.nix
  ];

  boot.loader.timeout = 1;

  boot.initrd.availableKernelModules = [ "hid_roccat_ryos" ];

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

  # Looks very similar the default console font and uni-vga though not 100%
  # TODO: Find out what the actual console font is and use that instead
  console.font = "cp1250";

  programs.screen.screenrc = "startup_message off";

  services.tailscale.enable = true;

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
    extraGroups = [ "wheel" "networkmanager" "docker" "video" "libvirtd" ];
    shell = pkgs.bash;
    initialPassword = "none";
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

    requireSignedBinaryCaches = false;

    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
    # maybe set to batch on non-desktop

    package = pkgs.customNix;
  };

  programs.command-not-found.dbPath = "/nix/var/nix/programs.sqlite";
}
