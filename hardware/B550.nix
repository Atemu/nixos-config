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

  boot.kernelPatches = [
    (lib.mkIf (lib.versions.majorMinor config.boot.kernelPackages.kernel.version == "5.15") {
      name = "amdgpu suspend fix";
      patch = pkgs.fetchpatch {
        url = "https://patchwork.freedesktop.org/patch/485708/raw/";
        sha256 = "sha256-1HWWfBDulZ0ewAt50BNfm9IgOcqO0QYyHFneeTRjkJc=";
      };
    })

    (lib.mkIf (config.boot.kernelPackages.kernel.kernelOlder "5.11") {
      name = "nct6687";
      patch = pkgs.fetchpatch {
        url = "https://patchwork.kernel.org/project/linux-hwmon/patch/20201202025057.5492-1-andareed@gmail.com/mbox/";
        sha256 = "02mhxzm7zjv6bnwfjg4m7n4cv1cplhx6vwg8lynd4l1x6h2mzwa8";
      };
    })
  ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";

  hardware.cpu.amd.updateMicrocode = true;

  hardware.opengl.extraPackages = with pkgs; [
    rocm-opencl-icd
    rocm-opencl-runtime
  ];
  environment.systemPackages = with pkgs; [
    radeontop
    rocm-smi
    umr
  ];
}
