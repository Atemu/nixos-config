{ config, lib, ... }:

let
  inherit (config.custom.luks) devices;
in

with lib;

{
  options.custom.luks.devices = mkOption { };

  config = {
    boot.initrd.luks.devices = lib.mapAttrs (n: v: {
      # Leaking space usage is not part of my threat model
      allowDiscards = true;
      # Improves performance: https://blog.cloudflare.com/speeding-up-linux-disk-encryption/
      bypassWorkqueues = true;
    } // v) devices;
  };
}
