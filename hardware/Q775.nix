{ config, lib, pkgs, ... }:

{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ "dm-snapshot" "i915" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  services.undervolt.coreOffset = -85;

  hardware.cpu.intel.updateMicrocode = true;

  services.logind.lidSwitchDocked = config.services.logind.lidSwitch;

  services.xserver.inputClassSections = [
    ''
      Identifier      "calibration"
      MatchProduct    "Wacom MultiTouch Sensor Pen stylus"
      Option  "MinX"  "243"
      Option  "MaxX"  "29555"
      Option  "MinY"  "-34"
      Option  "MaxY"  "16487"
    ''
    ''
      Identifier      "calibration"
      MatchProduct    "Wacom MultiTouch Sensor Pen eraser"
      Option  "MinX"  "126"
      Option  "MaxX"  "29448"
      Option  "MinY"  "-41"
      Option  "MaxY"  "16418"
    ''
    ''
      Identifier      "calibration"
      MatchProduct    "Wacom MultiTouch Sensor Finger touch"
      Option  "MinX"  "109"
      Option  "MaxX"  "11770"
      Option  "MinY"  "-4"
      Option  "MaxY"  "6608"
    ''
  ];

  powerManagement.resumeCommands =
    let resetUsbId = pkgs.writeShellScript "resetUsbId" ''
      #reset device by ID
      #based on https://forum.manjaro.org/t/keyboard-and-mouse-not-working-after-suspend/61424/35
      set -euo pipefail
      IFS=$'\n\t'

      VENDOR="$1"
      PRODUCT="$2"

      for DIR in $(find /sys/bus/usb/devices/ -maxdepth 1 -type l); do
        if [[ -f $DIR/idVendor && -f $DIR/idProduct &&
              $(cat $DIR/idVendor) == $VENDOR && $(cat $DIR/idProduct) == $PRODUCT ]]; then
          echo 0 > $DIR/authorized
          echo 1 > $DIR/authorized
        fi
      done
    '';
    in ''
      # Reset dock keyboard
      ${resetUsbId} 04c5 148a
      # Reset LTE modem on resume
      ${resetUsbId} 1199 9041
    '';
}
