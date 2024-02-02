{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [
    "kvm-amd"

    # The board's sensor controller
    "nct6687"
  ];
  boot.kernelParams = [
    "amd_iommu=on"
    "amd_pstate=active"
  ];
  boot.extraModulePackages = with config.boot.kernelPackages; [
    # It's an out-of-tree package
    nct6687d
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}