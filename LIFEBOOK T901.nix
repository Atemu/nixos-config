{ config, lib, pkgs, ... }:

{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ "ehci_pci" "ahci" "xhci_pci" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  nix.maxJobs = lib.mkDefault 4;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  hardware.cpu.intel.updateMicrocode = true;

  hardware.brightnessctl.enable = true;

  # After lid suspend, the T901 becomes "docked" for some reason.
  # Might be a systemd bug though because the kernel seems to react properly
  # This makes it suspend eventhough it's "docked"
  services.logind.lidSwitchDocked = "suspend";

  services.tlp.enable = true;

  services.xserver.wacom.enable = true;
}
