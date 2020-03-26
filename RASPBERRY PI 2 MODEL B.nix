{ config, lib, pkgs, ... }:

{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  swapDevices = [ ];

  nix.maxJobs = lib.mkDefault 4;

  nixpkgs.config.allowUnsupportedSystem = true;

  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}
