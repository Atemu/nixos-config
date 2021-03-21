{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules =
    # Ethernet
    [ "r8169" ]
    # Auto-generated
    ++ [ "ahci" "xhci_pci" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  swapDevices = [ ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  hardware.cpu.intel.updateMicrocode = true;
}
