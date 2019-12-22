# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ "ehci_pci" "ahci" "isci" "xhci_pci" "usbhid" "usb_storage" "sd_mod" "e1000e" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  swapDevices = [ ];

  fileSystems."/" = {
    device = "Kpool/K/root";
    fsType = "zfs";
  };
  fileSystems."/home/" = {
    device = "Kpool/K/home";
    fsType = "zfs";
  };
  fileSystems."/var/" = {
    device = "Kpool/K/var";
    fsType = "zfs";
  };
  fileSystems."/tmp/" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [ "size=50%" "nosuid" "nodev" "nodev" "mode=1777" ]; # systemd default security options
  };
  fileSystems."/boot/" = {
    device = "/dev/disk/by-uuid/237E-DD69";
    fsType = "vfat";
  };

  nix.maxJobs = lib.mkDefault 12;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
