{ pkgs, ... }:

{
  imports = [
    ../../common.nix
    ../../hardware/FW16.nix
  ];

  networking.hostName = "THESEUS";

  custom.secretPassword = true;

  custom.desktop.enable = true;
  custom.desktop.hypr.enable = true;

  boot.initrd.systemd.enable = true;

  custom.dnscrypt.enable = true;

  environment.systemPackages = with pkgs; [
    prusa-slicer
  ];

  custom.bootloader.choice = "systemd-boot";

  custom.luks.autoDevices = 1;

  custom.fs.enable = true;
  custom.fs.btrfs.enable = true;
  custom.fs.btrfs.newLayout = true;

  custom.replication.enable = true;
  custom.replication.replications.Root = {
    enable = true;
    exclude = [
      # Don't care about container storage on this host
      "var/lib/docker"
      "var/lib/containers"
      # Only for test purposes
      "var/lib/immich"
      "var/lib/postgresql"

      "var/lib/systemd/coredump"
      "var/lib/borg"

      # TODO separate volume
      "Volumes/Games"

      "var/cache"
      "var/tmp"
    ];
  };
  custom.replication.replications.Users = {
    enable = true;
    exclude = map (it: "atemu/${it}") [
      ".cache"
      ".local/share/Steam"
      ".local/share/Trash"

      "Repos/linux"
      "Projects/robotnix/avd"
      ".gradle"
      ".emacs.d/.cache"
      ".emacs.d/eln-cache"
      ".cargo"
      ".npm"
      "go"
    ];
  };

  # Device name must be provided by hardware config for now
  custom.swap.devices.primary.enable = true;

  system.stateVersion = "24.11";
}
