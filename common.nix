{ config, lib, pkgs, ... }:

let
  nixos-config = "/nix/var/nix/nixos-config";
  nixpkgs = "/nix/var/nix/nixpkgs";
in

{
  imports = [
    ./custom.nix
    ./desktop.nix
    ./dnscrypt.nix
    ./luks.nix
    ./overlays.nix
    ./packages.nix
    ./vm.nix
    ./zfs.nix
  ];

  boot.loader.timeout = 1;

  boot.initrd.availableKernelModules = [ "hid_roccat_ryos" ];

  console.earlySetup = true;

  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  time.timeZone = "Europe/Berlin";

  # Looks very similar the default console font and uni-vga though not 100%
  # TODO: Find out what the actual console font is and use that instead
  console.font = "cp1250";

  programs.screen.screenrc = "startup_message off";

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
    requireSignedBinaryCaches = false;
    daemonNiceLevel = 10;
  };

  programs.command-not-found.dbPath = "/nix/var/nix/programs.sqlite";
}
