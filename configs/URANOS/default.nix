{ lib, config, ... }:

{
  imports = [
    ../../common.nix

    ./storage.nix

    ../../hardware/UTM.nix
  ];

  custom.hostName = "URANOS";

  services.openssh.enable = true;

  programs.mosh.enable = true;

  custom.paperless.enable = true;
  custom.paperless.autoExport = true;
  # FIXME make virtualHost config accessible through as an option in custom.paperless
  custom.virtualHosts.paperless.onPrimaryDomain = false;

  custom.grocy.enable = true;
  custom.virtualHosts.grocy.onPrimaryDomain = false;

  custom.hedgedoc.enable = true;

  custom.mealie.enable = true;

  custom.vm.enable = true;

  system.stateVersion = "22.11";
}
