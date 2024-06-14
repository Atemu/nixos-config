{ pkgs, ... }:

{
  imports = [
    ../../common.nix
    ../../hardware/FW16.nix
  ];

  networking.hostName = "LYKOURGOS";

  custom.desktop.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;

  boot.initrd.systemd.enable = true;

  services.sshd.enable = true;

  virtualisation.docker.enable = true;

  programs.adb.enable = true;

  custom.dnscrypt.enable = true;

  custom.bootloader.choice = "systemd-boot";

  custom.luks.autoDevices = 1;

  custom.fs.enable = true;
  custom.fs.btrfs.enable = true;
  custom.fs.btrfs.newLayout = true;

  custom.zramSwap.enable = true;

  system.stateVersion = "24.11";
}
