{ pkgs, ... }:

{
  nixpkgs.hostPlatform = "aarch64-linux";

  boot.loader.grub.enable = false;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.raspberryPi.uboot.enable = true;
  boot.loader.raspberryPi.enable = true;
  boot.loader.raspberryPi.version = 3;
}
