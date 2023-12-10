{ lib, config, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkOption mkIf getBin;
  this = config.custom.paperless;
  cfg = config.services.paperless;
in

{
  options.custom.paperless = {
    enable = mkEnableOption "my custom paperless config";

    autoExport = mkEnableOption "efficient export of paperless content to the `export` directory under {option}`services.paperless.dataDir`";
  };

  config = mkIf this.enable {
    services.paperless.enable = true;
    services.paperless.address = "0.0.0.0";
    services.paperless.passwordFile = builtins.toFile "password" "none";
    services.paperless.extraConfig = {
      PAPERLESS_OCR_LANGUAGE = "deu";

      PAPERLESS_OCR_USER_ARGS = builtins.toJSON {
        optimize = 2;
        pdfa_image_compression = "auto";
        # Doesn't do anything because GhostScript compresses down to q=95
        # anyways; this serves to not degrade quality further
        jpeg_quality = 100;
      };

      PAPERLESS_OCR_OUTPUT_TYPE = "pdfa-3";

      PAPERLESS_NUMBER_OF_SUGGESTED_DATES = 42; # All the dates please

      PAPERLESS_FILENAME_FORMAT = "{correspondent}/{created} {title}";

      PAPERLESS_THREADS_PER_WORKER = 1;
      PAPERLESS_TASK_WORKERS = 4;

      PAPERLESS_URL = "https://${config.custom.virtualHosts.paperless.domain}";
    };

    networking.firewall.allowedTCPPorts = [ cfg.port ];

    custom.virtualHosts.paperless = {
      localPort = cfg.port;
    };

    systemd.timers.paperless-exporter = mkIf this.autoExport {
      timerConfig = {
        OnCalendar = "daily";
        Unit = "paperless-exporter.service";
      };
      wantedBy = [ "timers.target" ];
    };
    systemd.services.paperless-exporter = mkIf this.autoExport {
      serviceConfig.User = config.services.paperless.user;

      script = ''
        exportDir="${cfg.dataDir}/export"

        # Create hardlinks of all documents
        ${getBin pkgs.coreutils}/bin/cp --link --archive --update ${cfg.mediaDir}/documents/originals/. $exportDir

        # Run the exporter
        cmd=(
          ${cfg.dataDir}/paperless-manage document_exporter
          --compare-checksums
          --delete
          --no-archive
          --no-thumbnail
          --use-filename-format
          --split-manifest
          $exportDir
        ); "''${cmd[@]}"

        # Allow users of the paperless groups to inspect the backup
        find $exportDir -type f -exec chmod 640 {} +
        find $exportDir -type d -exec chmod 750 {} +
      '';
    };
  };
}
