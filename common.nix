{ config, lib, pkgs, ... }:

let
  nixos-config = "/nix/var/nix/nixos-config";
  nixpkgs = "/nix/var/nix/nixpkgs";

  inherit (lib) attrValues;
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

  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  time.timeZone = "Europe/Berlin";

  programs.screen.screenrc = "startup_message off";

  programs.fuse.userAllowOther = true;

  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = lib.mkDefault "client"; # May get overridden for a machine
  systemd.services.tailscaled.serviceConfig.LogLevelMax = 5; # Stop the info spam
  # FIXME https://github.com/NixOS/nixpkgs/issues/180175#issuecomment-1655787774
  networking.networkmanager.unmanaged = [ "tailscale0" ];

  # Stop log spam from my SOHO router's amazingly helpful port scanning
  networking.firewall.logRefusedConnections = false;

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
    in attrValues (removeAttrs hostKeys [ config.custom.hostName ]);
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
}
