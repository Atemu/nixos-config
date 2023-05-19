{ lib, config, ... }:

{
  options.custom.paperless = {
    enable = lib.mkEnableOption "my custom paperless config";
  };

  config = lib.mkIf config.custom.paperless.enable {
    services.paperless.enable = true;
    services.paperless.address = "0.0.0.0";
    services.paperless.passwordFile = builtins.toFile "password" "none";
    services.paperless.extraConfig = {
      PAPERLESS_OCR_LANGUAGE = "deu+eng";
      PAPERLESS_NUMBER_OF_SUGGESTED_DATES = 42; # All the dates please

      PAPERLESS_FILENAME_FORMAT = "{correspondent}/{created} {title}";

      PAPERLESS_ADMIN_USER = "atemu";

      PAPERLESS_THREADS_PER_WORKER = 1;
      PAPERLESS_TASK_WORKERS = 4;
    };

    networking.firewall.allowedTCPPorts = [ 28981 ];
  };
}
