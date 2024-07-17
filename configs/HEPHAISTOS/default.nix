{ config, pkgs, lib, ... }:

{
  imports = [
    ../../common.nix

    ./storage.nix

    ../../hardware/B650.nix
  ];

  networking.hostName = "HEPHAISTOS";

  custom.desktop.enable = true;

  custom.gaming.enable = true;
  custom.gaming.steamvr.unprivilegedHighPriorityQueue = true;

  boot.kernelPackages = pkgs.linuxPackages_xanmod_latest;

  boot.initrd.systemd.enable = true;

  services.sshd.enable = true;

  # Scanner
  # TODO refactor into module
  hardware.sane.enable = true;
  environment.systemPackages = with pkgs; [
    img2pdf
  ];

  virtualisation.docker.enable = true;

  programs.adb.enable = true;

  services.taler.enable = true;
  services.taler.exchange.enable = true;
  services.taler.exchange.debug = true;
  services.taler.exchange.denominationConfig = ''
    [COIN-KUDOS-n1-t1718140083]
    VALUE = KUDOS:0.1
    DURATION_WITHDRAW = 7 days
    DURATION_SPEND = 2 years
    DURATION_LEGAL = 6 years
    FEE_WITHDRAW = KUDOS:0
    FEE_DEPOSIT = KUDOS:0.1
    FEE_REFRESH = KUDOS:0
    FEE_REFUND = KUDOS:0
    RSA_KEYSIZE = 2048
    CIPHER = RSA
  '';
  services.taler.settings.taler.CURRENCY = "KUDOS";
  services.taler.settings.exchange = {
    MASTER_PUBLIC_KEY = "Q6KCV81R9T3SC41T5FCACC2D084ACVH5A25FH44S6M5WXWZAA8P0";
  };
  # TODO make abstraction for this
  # TODO automatically enable the accounts using taler-exchange-offline? Does that work without /keys?
  services.taler.settings.exchange-account-1 = {
    PAYTO_URI = "payto://x-taler-bank/${config.custom.virtualHosts.bank.domain}/exchange?receiver-name=exchange";
    ENABLE_DEBIT = "YES";
    ENABLE_CREDIT = "YES";
  };
  # TODO Provide an option for the auth password?
  services.taler.settings.exchange-accountcredentials-1 = {
    WIRE_GATEWAY_URL = "https://${config.custom.virtualHosts.bank.domain}/accounts/exchange/taler-wire-gateway/";
    WIRE_GATEWAY_AUTH_METHOD = "basic";
    USERNAME = "exchange";
    PASSWORD = "exchange";
  };
  services.taler.settings.libeufin-bank = {
    SUGGESTED_WITHDRAWAL_EXCHANGE = "https://${config.custom.virtualHosts.exchange.domain}/";

    WIRE_TYPE = "x-taler-bank";
  };

  services.taler.libeufin.bank.enable = true;
  services.taler.libeufin.bank.debug = true;

  custom.virtualHosts.exchange.localPort = 8081;
  custom.virtualHosts.bank.localPort = 8082;

  custom.dnscrypt.enable = true;

  services.postgresql.enable = true;
  services.postgresql.package = pkgs.postgresql_15;

  system.stateVersion = "20.09";
}
