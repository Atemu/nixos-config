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
          curve = let
            # The fans are not audible at such low RPM but keep it quite a bit
            # cooler.
            idle = 0.27;
            # The card has many resonant frequencies. 45% is not resonant and
            # provides ample cooling while gaming; keeping the card a good bit
            # below 90°C which is a bit better than the default fan curve even.
            operating = 0.45;
          in {
            # Don't turn the fans off! This would cause the GPU to accumulate
            # heat over time and impact the CPU's ability to dissipate its heat.
            "0" = idle;
            "40" = idle;
            "54" = idle;
            # I want a quick jump to operating speed rather than a ramp here to
            # avoid hitting resonant frequencies which are quite audible
            "55" = operating;

            "80" = operating;
            "90" = operating;

            "94" = operating;
            # If we're hot, COOL TF DOWN.
            # Please still don't ramp though
            "95" = 0.6;
            "100" = 1.0;
          };
        };
      };
    };
  };
}
