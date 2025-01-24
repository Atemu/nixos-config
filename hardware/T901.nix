{ config, lib, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
  ];

  boot.initrd.availableKernelModules = [
    "ehci_pci"
    "ahci"
    "xhci_pci"
    "usb_storage"
    "sd_mod"
    "sdhci_pci"
  ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  nix.maxJobs = lib.mkDefault 4;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  hardware.cpu.intel.updateMicrocode = true;

  # After lid suspend, the T901 becomes "docked" for some reason.
  # Might be a systemd bug though because the kernel seems to react properly
  # This makes it ignore the docked state for the lidSwitch action
  services.logind.lidSwitchDocked = config.services.logind.lidSwitch;

  services.xserver.wacom.enable = true;
  services.xserver.inputClassSections = [
    ''
      Identifier "Disable rfkill button"
      MatchProduct  "FUJ02E3"
      Option  "Ignore"  "true"
    ''
    # Disable wacom gestures, stolen from the Gentoo wiki
    ''
      Identifier "Wacom class"
      MatchProduct "Wacom|WACOM|Hanwang|PTK-540WL|ISDv4|ISD-V4|ISDV4"
      MatchDevicePath "/dev/input/event*"

      Driver "wacom"
      Option "Gesture" "off"
    ''
  ];

  systemd.sockets.systemd-rfkill.enable = false;
  systemd.services."systemd-rfkill@".enable = false;
  systemd.services.systemd-rfkill.enable = false;
}
