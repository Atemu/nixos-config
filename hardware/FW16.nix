{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "thunderbolt"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.kernelModules = [ "kvm-amd" ];

  # I don't trust newer kernel to not introduce nasty bugs
  boot.kernelPackages = pkgs.linuxPackages_6_6;

  custom.amdgpu.kernelModule.patches = [
    (pkgs.fetchpatch2 {
      url = "https://lore.kernel.org/lkml/20240610-amdgpu-min-backlight-quirk-v1-1-8459895a5b2a@weissschuh.net/raw";
      hash = "sha256-tXxI+G9nNc+p4y8ITISe7EioCtETtePpeuCr+oWT/+4=";
    })
  ];

  services.fprintd.enable = true;
  services.fwupd.enable = true;

  services.power-profiles-daemon.enable = true;
  custom.desktop.hypr.hypridle-power = true;

  hardware.bluetooth.enable = true;

  environment.systemPackages = with pkgs; [
    # Can change things like fan speed and charge limit
    fw-ectool
    # For EQ'in the speakers; they really need it
    easyeffects
  ];

  # TODO abstract into module where you can specify which program to use
  # internally
  security.wrappers.powerlimit = {
    owner = "root";
    group = "root";
    setuid = true;
    # Cannot use writeShellApplication because bash drops privileges gained via
    # SUID. Thanks a bunch. We need to use dash.
    source = pkgs.writeTextFile {
      name = "powerlimit";
      text = ''
        #!${lib.getExe pkgs.dash}

        export PATH="${
          lib.makeBinPath (
            with pkgs;
            [
              coreutils
              fw-ectool
            ]
          )
        }"

        ${lib.readFile ./powerlimit.sh}
      '';
      executable = true;
    };
    program = "pl";
  };

  custom.swap.devices.primary = {
    partUUID = "097f36ea-d602-48c3-b732-5c176bdc0512";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
