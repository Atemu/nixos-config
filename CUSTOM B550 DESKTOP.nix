{ lib, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.kernelParams = [ "amd_iommu=on" ];
  boot.extraModulePackages = [ ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  hardware.cpu.amd.updateMicrocode = true;
}
