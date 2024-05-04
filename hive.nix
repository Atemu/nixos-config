let
  nixfiles = with builtins; mapAttrs (n: v: ../${n}) (builtins.readDir ../.);
  getFromNixfiles = thing:
    if builtins.hasAttr thing nixfiles
    then nixfiles."${thing}"
    else builtins.trace "warning: nixfiles not present, using ${thing} from $NIX_PATH!" (builtins.findFile builtins.nixPath thing);
  nixpkgs = getFromNixfiles "nixpkgs";
  nixpkgs-2311 = getFromNixfiles "nixpkgs-23.11";
in
{
  meta = {
    # Override to pin the Nixpkgs version (recommended). This option
    # accepts one of the following:
    # - A path to a Nixpkgs checkout
    # - The Nixpkgs lambda (e.g., import <nixpkgs>)
    # - An initialized Nixpkgs attribute set
    inherit nixpkgs;

    # You can also override Nixpkgs by node!
    nodeNixpkgs = {
      SOTERIA = nixpkgs-2311;
    };

    # If your Colmena host has nix configured to allow for remote builds
    # (for nix-daemon, your user being included in trusted-users)
    # you can set a machines file that will be passed to the underlying
    # nix-store command during derivation realization as a builders option.
    # For example, if you support multiple orginizations each with their own
    # build machine(s) you can ensure that builds only take place on your
    # local machine and/or the machines specified in this file.
    # machinesFile = ./machines.client-a;
  };

  defaults = { lib, config, name, ... }: {
    # This module will be imported by all hosts
    imports = [
      ./common.nix
    ];
    # The name and nodes parameters are supported in Colmena,
    # allowing you to reference configurations in other nodes.
    networking.hostName = name;

    # I can't imagine a scenario where I wouldn't want the closure to be built
    # on the machine itself.
    deployment.buildOnTarget = true;

    # Allow desktop machines to be managed locally
    deployment.allowLocalDeployment = config.custom.desktop.enable;

    deployment.targetUser = null; # Don't specify
    deployment.targetHost = config.lib.custom.concatDomain [
      (lib.toLower name)
      config.custom.acme.primaryDomain
    ];

    # By default, Colmena will replace unknown remote profile
    # (unknown means the profile isn't in the nix store on the
    # host running Colmena) during apply (with the default goal,
    # boot, and switch).
    # If you share a hive with others, or use multiple machines,
    # and are not careful to always commit/push/pull changes
    # you can accidentaly overwrite a remote profile so in those
    # scenarios you might want to change this default to false.
    # deployment.replaceUnknownProfiles = true;
  };
}
// builtins.mapAttrs
  (n: v: { ... }: { imports = [ v ]; }) # TODO set deployment.targetHost based on hostname # actually, do that in some custom module, you have the name input anyways
  (import ./configs)
