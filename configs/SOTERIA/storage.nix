# This file contains the configuration of disks and storage
{ config, ... }:

with config.lib.custom;

{
  custom.fs.enable = true;
  custom.fs.boot = mkUuid "21F5-7652";
  custom.fs.btrfs.enable = true;
  custom.fs.btrfs.device = mkUuid "53a12e2b-fdd8-4b83-ba37-369baa7ec1ab";

  boot.supportedFilesystems = [ "zfs" ];

  boot.loader.grub.devices = [ "nodev" ];
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.efiSupport = true;

  boot.initrd.luks.devices = {
    SAMSUNG_MZ7LN256HCHP-crypt = {
      device = mkUuid "82a2b716-11ca-4c0b-8c4f-5470b8a97bd9";
      allowDiscards = true;
    };

    TRION100-crypt = {
      device = "/dev/disk/by-uuid/140c8ebf-0664-47d6-8c71-cf9ef655efe0";
      allowDiscards = true;
    };
    WD10EADS-crypt = {
      device = "/dev/disk/by-uuid/90fcb44c-275a-4641-99c6-9c36b753f283";
    };
    WD10EZEX-crypt = {
      device = "/dev/disk/by-uuid/41c3bb59-d732-4e53-99c5-4ab346f143b9";
    };
    ST1000DM003-crypt = {
      device = "/dev/disk/by-uuid/b22bbe9d-3513-4d93-81ee-6ce60da0bab1";
    };
    ST2000DM006-crypt = {
      device = "/dev/disk/by-uuid/e9b4abff-8f8d-4bd1-a366-1938a89c12bf";
    };
  };
}
