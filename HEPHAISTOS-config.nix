{ config, pkgs, ... }:

{
  imports = [
    ./desktop.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_5_7;
  boot.kernelPatches = [
    {
      name = "fsync";
      patch = pkgs.fetchpatch {
        name = "futex-wait-multiple-5.2.1.patch";
        url = "https://aur.archlinux.org/cgit/aur.git/plain/futex-wait-multiple-5.2.1.patch?h=linux-fsync&id=06b35b38cf9932ee3209e941a1e3a41c663f519b";
        sha256 = "0z2wxqjcnsg6flcq1jk9wv8r8y2sm52iwv3lndpr1sizr3q5xr3q";
      };
    }
  ];

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.steam-hardware.enable = true;

  services.sshd.enable = true;

  virtualisation.libvirtd = {
    enable = true;
    qemuOvmf = true;
    qemuRunAsRoot = false;
  };

  programs.adb.enable = true;

  system.stateVersion = "20.09";
}
