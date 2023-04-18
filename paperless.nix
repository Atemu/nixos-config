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

      PAPERLESS_ADMIN_USER = "atemu";
      PAPERLESS_THREADS_PER_WORKER = 4;
      PAPERLESS_TASK_WORKERS = 2;
    };

    networking.firewall.allowedTCPPorts = [ 28981 ];
  };
}
