# This file contains the configuration of disks and storage
{ config, ... }:
{
  boot.loader.grub.devices = [ "/dev/disk/by-id/ata-OCZ-TRION100_95EB50GYKMFX" ];

  boot.initrd.luks.devices = {
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
