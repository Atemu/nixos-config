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

  custom.gaming.amdgpu = true;

  custom.lact = {
    enable = true;
    settings = {
      # My 6800 XT
      gpus."1002:73BF-148C:2406-0000:03:00.0" = {
        # Work around https://gitlab.freedesktop.org/drm/amd/-/issues/1500
        performance_level = "manual";
        power_profile_mode_index = 4; # VR

        # A more moderate fan curve
        fan_control_enabled = true;
        fan_control_settings = {
          mode = "curve";
          # I only care about Tj
          temperature_key = "junction";
          interval_ms = 500;
          curve = {
            # Don't turn the fans off! This would cause the GPU to accumulate
            # heat over time and actually affect the CPU's ability to dissipate
            # its own heat. The fans are not audible at such low RPM but keep it
            # quite a bit cooler.
            "0" = 0.27;
            "40" = 0.27;
            "54" = 0.27;
            # I want a quick jump rather than a ramp here
            "55" = 0.45;

            # The card has many resonant frequencies; ramping the fan speed will
            # hit all of them which is quite audible. 45% is not resonant and
            # provides ample cooling while gaming; keeping the card a good bit
            # below 90°C which is a bit better than the default fan curve even.
            "80" = 0.45;
            "90" = 0.45;
            "94" = 0.45;

            # If it's not, COOL TF DOWN.
            "95" = 0.6;
            "100" = 1.0;
          };
        };
      };
    };
  };
}
