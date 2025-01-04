{
  lib,
  config,
  ...
}:

let
  this = config.custom.paperless;
  cfg = config.services.paperless;

  exportDir = cfg.exporter.directory;
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
    services.paperless.exporter = lib.mkIf this.autoExport {
      enable = true;

      directory = cfg.dataDir + "/export";

      onCalendar = "daily";

      options = lib.genAttrs [
        "compare-checksums"
        "delete"
        "no-archive"
        "no-thumbnail"
        "use-filename-format"
        "split-manifest"
      ] (_: true);

      # Create hardlinks of all documents
      preScript = ''
        cp --link --archive --update ${cfg.mediaDir}/documents/originals/. ${exportDir}
      '';
      # Allow users of the paperless groups to inspect the backup
      postScript = ''
        find ${exportDir} -type f -exec chmod 640 {} +
        find ${exportDir} -type d -exec chmod 750 {} +
      '';
    };

    custom.virtualHosts.paperless = {
      localPort = cfg.port;
    };
  };
}
