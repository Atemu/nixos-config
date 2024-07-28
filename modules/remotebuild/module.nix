{ lib, config, ... }:

let
  this = config.custom.remotebuild;
in

{
  options.custom.remotebuild = {
    enable = lib.mkEnableOption "remote builds";

    builders = {
      cccda = lib.mkEnableOption "cccda remote builders";
    };

    sshKey = lib.mkOption { default = "${config.users.users.atemu.home}/.ssh/id_ed25519"; };
  };

  config = lib.mkIf this.enable (lib.mkMerge [
    (lib.mkIf this.builders.cccda {
      # https://git.darmstadt.ccc.de/noc/builders-nix#configuring-your-computer-for-remote-builds
      programs.ssh.knownHosts = {
        "build1.darmstadt.ccc.de".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE/oyJPRwW3bJoWKtXSrVOiqMaKq+9yd03+N2PuCbMKv";
        "build2.darmstadt.ccc.de".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOZ7/eZLTfUD7Ejjio+8ivNFb8iyK1CD5Pq8uCDojT+z";
        "build3.darmstadt.ccc.de".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM2D/SwJf46XCoim06lOyO42JqJiTeM8UMkT4bYluJJr";
        "build4.darmstadt.ccc.de".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDu9ZsbUYaCzzZv4vn22KrKi/R9pCfOEe4aYWyLd96C1";
      };

      nix = {
        distributedBuilds = true;
        buildMachines =
          let
            common = {
              protocol = "ssh";
              sshUser = "atemu";
              inherit (this) sshKey;
              systems = [
                "i686-linux"
                "x86_64-linux"
              ];
              maxJobs = 4;
              speedFactor = 6;
              supportedFeatures = [
                "big-parallel"
                "kvm"
                "nixos-test"
              ];
            };
          in
          map (builder: common // builder) [
            { hostName = "build1.darmstadt.ccc.de"; }
            { hostName = "build2.darmstadt.ccc.de"; }
            { hostName = "build3.darmstadt.ccc.de"; }
            {
              hostName = "build4.darmstadt.ccc.de";
              # this node has half the cpu of the others
              maxJobs = 2;
              speedFactor = 6;
            }
          ];
      };
    })
  ]);
}
