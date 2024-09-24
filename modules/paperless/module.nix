{ lib, config, pkgs, ... }:

let
  this = config.custom.paperless;
  cfg = config.services.paperless;

  services = [
    "paperless-consumer.service"
    "paperless-scheduler.service"
    "paperless-task-queue.service"
    "paperless-web.service"
  ];
in

{
  options.custom.paperless = {
    enable = lib.mkEnableOption "my custom paperless config";

    autoExport = lib.mkEnableOption "efficient export of paperless content to the `export` directory under {option}`services.paperless.dataDir`";
  };

  config = lib.mkIf this.enable {
    services.paperless.enable = true;
    services.paperless.address = "0.0.0.0";
    services.paperless.passwordFile = builtins.toFile "password" "none";
    services.paperless.settings = {
      PAPERLESS_OCR_LANGUAGE = "deu";

      PAPERLESS_OCR_USER_ARGS = builtins.toJSON {
        optimize = 2;
        pdfa_image_compression = "auto";
        # Doesn't do anything because GhostScript compresses down to q=95
        # anyways; this serves to not degrade quality further
        jpeg_quality = 100;

        # Paperless refuses to handle signed PDFs (i.e. Docusign) by default
        # because its OCR would invalidate the signature. Since paperless keeps
        # originals however, this is of no relevance to me.
        # https://github.com/paperless-ngx/paperless-ngx/discussions/4830
        invalidate_digital_signatures = true;
      };

      PAPERLESS_OCR_OUTPUT_TYPE = "pdfa-3";

      PAPERLESS_NUMBER_OF_SUGGESTED_DATES = 42; # All the dates please

      PAPERLESS_FILENAME_FORMAT = "{correspondent}/{created} {title}";

      PAPERLESS_THREADS_PER_WORKER = 1;
      PAPERLESS_TASK_WORKERS = 4;

      PAPERLESS_URL = "https://${config.custom.virtualHosts.paperless.domain}";
    };

    custom.virtualHosts.paperless = {
      localPort = cfg.port;
    };

    systemd.services.paperless-exporter = lib.mkIf this.autoExport {
      serviceConfig.User = config.services.paperless.user;

      unitConfig = {
        # Shut down the paperless services while the exporter runs
        Conflicts = services;
        After = services;
        # Bring them back up afterwards, regardless of pass/fail
        OnFailure = services;
        OnSuccess = services;
      };

      script = ''
        exportDir="${cfg.dataDir}/export"

        # Create hardlinks of all documents
        ${lib.getBin pkgs.coreutils}/bin/cp --link --archive --update ${cfg.mediaDir}/documents/originals/. $exportDir

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

      startAt = "daily";
    };
  };
}
