{ config, lib, pkgs, ... }:

{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.kernel.sysctl = {
    # Help with running OOM during builds
    "vm.overcommit_memory" = 1; # always overcommit
    "vm.overcommit_ratio" = 100; # how much of the total VM should be allocatable by processes
  };
  boot.extraModulePackages = [ ];

  # We need the raspi bootloader with uboot
  boot.loader.raspberryPi.enable = true;
  boot.loader.raspberryPi.uboot.enable = true;
  # Do not use GRUB
  boot.loader.grub.enable = false;

  swapDevices = [ ];

  nix.maxJobs = lib.mkDefault 4;

  nixpkgs.config.allowUnsupportedSystem = true;

  nix.binaryCachePublicKeys = [ "thefloweringash-armv7.cachix.org-1:v+5yzBD2odFKeXbmC+OPWVqx4WVoIVO6UXgnSAWFtso=" ];
  nix.binaryCaches = [ "https://thefloweringash-armv7.cachix.org/" ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}
