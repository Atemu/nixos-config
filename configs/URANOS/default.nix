{ lib, ... }:

{
  imports = [
    ../../common.nix

    ./storage.nix

    ../../hardware/UTM.nix
  ];

  custom.hostName = "URANOS";

  services.openssh.enable = true;

  programs.mosh.enable = true;

  custom.vm.enable = true;

  # Libvirt takes forever to start, socket activate it when I actually need it
  systemd.services.libvirtd.wantedBy = lib.mkForce [ ];
  systemd.services.libvirtd-config.wantedBy = lib.mkForce [ ];
  systemd.services.mount-pstore.wantedBy = lib.mkForce [ ];

  systemd.defaultUnit = "default-online.target";
  systemd.targets.default-online.wants = [ "multi-user.target" "network-online.target" ];

  # Be required by graphical-online rather than multi-user.
  systemd.targets.network-online.wantedBy = lib.mkForce [ "graphical-online.target" ];

  systemd.services.tailscaled.wantedBy = lib.mkForce [ ];

  # Don't need this feature.
  systemd.services.libvirt-guests.wantedBy = lib.mkForce [ ];

  # Why is this in the multi-user.target? Only network-online should care.
  systemd.services.dhcpcd.wantedBy = lib.mkForce [ "network-online.target" ];

  system.stateVersion = "22.11";
}
