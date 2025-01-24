{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "usbhid"
    "sd_mod"
  ];
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
          # Only spin down after 30s. This is in order to prevent jumps during a
          # loading screen or other short periods of less GPU activity.
          spindown_delay_ms = 30000;
          curve =
            let
              # The fans are not audible at such low RPM but keep it quite a bit
              # cooler.
              idle = 0.27;
              # The card has many resonant frequencies. 45% is not resonant and
              # provides ample cooling while gaming; keeping the card a good bit
              # below 90°C which is a bit better than the default fan curve even.
              operating = 0.45;
            in
            {
              # Don't turn the fans off! This would cause the GPU to accumulate
              # heat over time and impact the CPU's ability to dissipate its heat.
              "0" = idle;
              # This is the idle range. I technically don't need the fan speeds to
              # be in the operating range until it's at 80-something but I don't
              # want the speeds to jump up and down during loading screens or
              # other short downtimes or ramp up during very light load.
              "79" = idle;
              # I want a quick jump to operating speed rather than a ramp here to
              # avoid hitting resonant frequencies which are quite audible
              "80" = operating;
              # This is the operating temperature range
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
