{ lib, config, ... }:

with lib;

let
  cfg = config.custom.zramSwap;
in

{
  options.custom.zramSwap = {
    enable = mkEnableOption "my custom ZRAM Swap config";
    percent = mkOption {
      description = ''
        How much of the total system memory to use for zram swap.

        This should be set to the maximum amount possible that doesn't endanger essential applications like the kernel when 100% of it is utilised for swap.
      '';
      default = 50;
    };
  };

  config.zramSwap = mkIf cfg.enable {
    enable = true;
    algorithm = "lz4";
    memoryPercent = cfg.percent;
  };
}
