{ config, lib, ... }:

let
  this = config.custom.swap;
in

{
  options.custom.swap.devices = lib.mkOption {
    description = "Configure disk-backed swap devices";
    type = lib.types.attrsOf (lib.types.submodule ({ ... }: {
      options = {
        enable = lib.mkEnableOption "this device";
        partUUID = lib.mkOption {
          description = "The partUUID of the device";
          type = lib.types.str;
        };
        random = lib.mkEnableOption "random encryption" // lib.mkOption { default = true; };
      };
    }));
    default = { };
  };
  options.custom.swap.zswap = {
    enable = lib.mkEnableOption "sensible zswap settings" // lib.mkOption { default = true; };
  };

  config = let
    enabledDevices = lib.filterAttrs (n: v: v.enable) this.devices;
  in lib.mkIf (enabledDevices != { }) {
    swapDevices = lib.mapAttrsToList (_: device: {
      device = "/dev/disk/by-partuuid/${device.partUUID}";
      randomEncryption = {
        enable = device.random;
        sectorSize = 4096; # Pages are 4k anyways
        # Does not expose information other than how much swap I'm using which I
        # don't care about.
        allowDiscards = true;
      };
    }) enabledDevices;

    systemd.tmpfiles.rules = lib.mkIf this.zswap.enable (
      lib.mapAttrsToList (n: v: "w /sys/module/zswap/parameters/${n}  - - - - ${toString v}") {
        enabled = true;

        # I think with swap, you need speed first and foremost and compression
        # efficiency is secondary. OTOH, in my testing, zstd is able to store
        # the first 3 pages of random files in my closure in 1 page ~40% of
        # the time vs. only ~10% with lz4 although the bulk is 2 pages in
        # either case. I consider zswap as a best-effort speed efficiency
        # boost though, so speed is more important I think.
        compressor = "lz4";

        # AFAIK zsmalloc has memory fragmentation issues because it concatenates
        # compressed pages with no regard for page boundaries. Reading a single
        # page from compressed memory might require reading many pages. z3fold
        # does not have such issues and a 3:1 compression ratio is good enough for
        # me; the same point about me merely considering zswap an efficiency
        # booster applies here.
        zpool = "z3fold";

        # This controls how much of the system RAM may be taken up by swap. On the
        # one hand, you might think one wants this as high as possible but you
        # must consider that at some point you do actually want stuff to be
        # swapped out to disk as zswap is merely a stage between memory and swap
        # that is cheaper than actual swap in terms of performance but still
        # requires memory; memory that is still taken away from file-backed pages.
        # Let's keep the default limit of 20% until I have formed a better opinion
        # on this.
        # max_pool_percent = "20";
      }
    );
  };
}
