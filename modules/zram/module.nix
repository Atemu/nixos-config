{ lib, config, ... }:

let
  this = config.custom.swap.zram;
in

{
  imports = [
    (lib.mkAliasOptionModule [ "custom" "zramSwap" ] [ "custom" "swap" "zram" ])
  ];
  options.custom.swap.zram = {
    enable = lib.mkEnableOption "my custom ZRAM Swap config";
    percent = lib.mkOption {
      description = ''
        How much of the total system memory to use for zram swap.

        This should be set to the maximum amount possible that doesn't endanger essential applications like the kernel when 100% of it is utilised for swap.
      '';
      default = 85;
    };
  };

  config.zramSwap = lib.mkIf this.enable {
    enable = true;
    algorithm = "lz4";
    memoryPercent = this.percent;
  };
}
