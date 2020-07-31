# This file implements things I want to have on all my NixOS machines and
# automatically includes host- and hardware-specific configuration based on
# the imperatively generated meta.nix. See README.md for more information.

# Given by build.nix
meta:

# Given by Nixpkgs
{ config, lib, pkgs, ... }:

let
  nixosConfig = "/nix/var/nix/nixos-config";
in

{
  imports =
    let
      pathWithFallback = path: fallback:
        if builtins.pathExists path then
          path
        else
          fallback;
      pathsWithFallbacks = paths: lib.foldr pathWithFallback { } paths;
    in
      [
        # Include host-specific configuration
        (pathsWithFallbacks [ (./. + "/${meta.hostName}-config.nix") /mnt/etc/nixos/configuration.nix /etc/nixos/configuration.nix ])

        # Include host-specific storage configuration
        (pathsWithFallbacks [ (./. + "/${meta.hostName}-storage.nix") ])

        # Include hardware-specific configuration
        (pathsWithFallbacks [ (./. + "/${meta.productName}.nix") /mnt/etc/nixos/hardware-configuration.nix /etc/nixos/hardware-configuration.nix ])

        (if (meta.withPackages or true) then ./packages.nix else { })

        # Service-specific configurations
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

  # Unstable channel pkgs override; e.g. pkgs.unstable.firefox
  nixpkgs.config.packageOverrides = pkgs: {
    unstable = import <nixos-unstable> {
      # pass the nixpkgs config to the unstable alias
      # to ensure `allowUnfree` is propagated:
      config = config.nixpkgs.config;
    };
  };
  nixpkgs.config.allowUnfree = true; # required for Steam

  programs.screen.screenrc = "startup_message off";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.atemu = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" "video" "libvirtd" ];
    shell = pkgs.bash;
    initialPassword = "none";
  };

  # FIXME only replace nixos-config= instead of overwriting the whole path
  nix.nixPath = [ "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos" "nixos-config=${nixosConfig}" "/nix/var/nix/profiles/per-user/root/channels" ];
  environment.variables.NIXOS_CONFIG_DIR = "${nixosConfig}";
}
