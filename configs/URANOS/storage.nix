{ config, ... }:

with config.lib.custom;

{
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;

  custom.fs.enable = true;
  custom.fs.boot = mkUuid "21F5-7652";
  custom.fs.btrfs.enable = true;
  custom.fs.btrfs.device = mkUuid "53a12e2b-fdd8-4b83-ba37-369baa7ec1ab";
  custom.fs.btrfs.newLayout = true;
}
