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
    package = pkgs.nixUnstable.overrideAttrs (old: {
      postInstallCheck = ''
        mv $out/bin/nix $out/bin/nixUnstable
        ln $out/bin/nixUnstable $out/bin/nixFlakes
        for cmd in $out/bin/nix-* ; do ln -sf nixUnstable "$cmd" ; done

        ln -s ${pkgs.nixStable}/bin/nix $out/bin/nixStable
        ln -s $out/bin/nixStable $out/bin/nix

        mv $out/share/bash-completion/completions/nix $out/share/bash-completion/completions/nixUnstable
        cp -a $out/share/bash-completion/completions/nixUnstable $out/share/bash-completion/completions/nixFlakes
        substituteInPlace $out/share/bash-completion/completions/nixUnstable --replace " nix" " nixUnstable"
        substituteInPlace $out/share/bash-completion/completions/nixFlakes --replace " nix" " nixFlakes"
      '';
      doCheck = false;
    });
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    requireSignedBinaryCaches = false;
  };

  programs.command-not-found.dbPath = "/nix/var/nix/programs.sqlite";
}
