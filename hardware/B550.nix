{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [
    "kvm-amd"

    # The board has an NCT6687D which is supported by the NCT6683 module
    "nct6683"
  ];
  boot.kernelParams = [ "amd_iommu=on" ];
  boot.extraModulePackages = [ ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";

  hardware.cpu.amd.updateMicrocode = true;

  hardware.opengl.package = pkgs.mesa_22_2.drivers;

  hardware.opengl.extraPackages = with pkgs; [
    rocm-opencl-icd
    rocm-opencl-runtime
  ];
  environment.systemPackages = with pkgs; [
    radeontop
    rocm-smi
    umr
  ];

  programs.corectrl.enable = true;
}
