{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkOption mkIf;
  this = config.custom.lact;

  configFile = pkgs.runCommand "lact-config.yaml" {
    json = pkgs.writers.writeJSON "lact-config.json" this.settings;
  } ''
    # Merge with the defaults
    ${lib.getExe pkgs.yq} -s '.[0] * .[1]' $json ${./lact-default-config.yaml} > config.json
    # Convert keys to numeric values where possible. It depends on this for some reason.
    ${lib.getExe pkgs.yj} -jy -k < config.json > $out
  '';
in

{
  options.custom.lact = {
    enable = mkEnableOption "my LACT module";
    settings = mkOption {
      default = { };
      type = lib.types.submodule {
        freeformType = (pkgs.formats.yaml { }).type;
      };
      description = ''
        Settings for LACT. Settings are merged with the defaults.

        The easiest method of acquiring the settings is to delete
        `/etc/lact/config.yaml`, enter your settings and look at the file.
      '';
    };
  };

  config = mkIf this.enable {
    systemd.packages = with pkgs; [
      lact
    ];
    systemd.services.lactd.wantedBy = [ "multi-user.target" ];

    environment.etc."lact/config.yaml" = mkIf (this.settings != { }) {
      source = configFile;
    };
    systemd.services.lactd = {
      # Restart if config changed
      restartTriggers = mkIf (this.settings != { }) [ configFile ];
    };
  };
}

