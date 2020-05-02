{ config, lib, pkgs, ... }:

{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # Use the extlinux bootloader instead of GRUB
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.grub.enable = false;

  swapDevices = [ ];

  nix.maxJobs = lib.mkDefault 4;

  nixpkgs.config.allowUnsupportedSystem = true;

  nix.binaryCachePublicKeys = [ "thefloweringash-armv7.cachix.org-1:v+5yzBD2odFKeXbmC+OPWVqx4WVoIVO6UXgnSAWFtso=" ];
  nix.binaryCaches = [ "https://thefloweringash-armv7.cachix.org/" ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}
