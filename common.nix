# This file implements things I want to have on all my NixOS machines and
# automatically includes host- and hardware-specific configuration based on
# the imperatively generated meta.nix. See README.md for more information.

# Given by build.nix
meta:

# Given by Nixpkgs
{ config, lib, pkgs, ... }:

let
  nixos-config = "/nix/var/nix/nixos-config";
  nixpkgs = "/nix/var/nix/nixpkgs";
in

{
  imports = [
    (./machines + "/${meta.hostName}/default.nix")
    (./machines + "/${meta.hostName}/storage.nix")
    (./hardware + "/${meta.productName}.nix")

    (if (meta.withPackages or true) then ./packages.nix else { })

    ./dnscrypt.nix
  ];

  boot.loader.timeout = 1;

  console.earlySetup = true;

  networking.hostName = meta.hostName;
  # The hostId is set to the crc32 of the hostName in hex
  networking.hostId =
    builtins.readFile (
      pkgs.runCommand "mkHostId" {} ''
        printf '%X' $(printf "${meta.hostName}" | cksum | cut -d ' '  -f1) > $out
      ''
    );

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
  ];
  environment.variables.NIXOS_CONFIG_DIR = "${nixos-config}";

  systemd.services.nix-daemon.environment.TMPDIR = "/var/tmp/";
}
