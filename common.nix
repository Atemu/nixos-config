# This file implements things I want to have on all my NixOS machines and
# automatically includes host- and hardware-specific configuration based on
# the imperatively generated meta.nix. See README.md for more information.

{ config, lib, pkgs, ... }:

let
  # meta.nix provides hostName and productName
  meta = import ./meta.nix;
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
    in
      [
        # Include host-specific configuration
        (pathWithFallback (./. + "/${meta.hostName}-config.nix") ./genericHost.nix)

        # Include host-specific storage configuration
        (pathWithFallback (./. + "/${meta.hostName}-storage.nix") null)

        # Include hardware-specific configuration
        (pathWithFallback (./. + "/${meta.productName}.nix") /etc/nixos/hardware-configuration.nix)

      ];

  boot.loader.timeout = 1;

  boot.earlyVconsoleSetup = true;

  networking.hostName = meta.hostName;
  # The hostId is set to the crc32 of the hostName in hex
  # TODO clean up this beauty
  networking.hostId =
    builtins.readFile (
      pkgs.runCommand "mkHostId" {} ''
      printf '%X' $(printf "${meta.hostName}" | cksum | cut -d \  -f1) > $out
      ''
    );

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.consoleKeyMap = "us";

  time.timeZone = "Europe/Berlin";

  # Looks very similar the default console font and uni-vga though not 100%
  # TODO: Find out what the actual console font is and use that instead
  i18n.consoleFont = "cp1250";

  # Unstable channel pkgs override; e.g. pkgs.unstable.firefox
  nixpkgs.config.packageOverrides = pkgs: {
    unstable = import <nixos-unstable> {
      # pass the nixpkgs config to the unstable alias
      # to ensure `allowUnfree` is propagated:
      config = config.nixpkgs.config;
    };
  };
  nixpkgs.config.allowUnfree = true; # required for Steam

  # List of packages installed in system profile.
  # If the host config enables X, X packages are also imported
  environment.systemPackages = with import ./systemPackages.nix pkgs;
                               common ++ (if config.services.xserver.enable then x else noX);

  programs.screen.screenrc = "startup_message off";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.atemu = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" "video" ];
    shell = pkgs.bash;
    initialPassword = "none";
  };

  # FIXME only replace nixos-config= instead of overwriting the whole path
  nix.nixPath = [ "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos" "nixos-config=${nixosConfig}" "/nix/var/nix/profiles/per-user/root/channels" ];
  environment.variables.NIXOS_CONFIG_DIR = "${nixosConfig}";
}
