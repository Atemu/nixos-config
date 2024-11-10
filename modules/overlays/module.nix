{ lib, config, ... }:

let
  this = config.custom.overlays;
in

{
  options.custom.overlays = {
    enable = lib.mkEnableOption "my custom overlays";
  };

  config.nixpkgs.overlays = lib.mkIf this.enable [
    (final: prev: {
      # A firefox with PGO, enabled in regular from-source firefox since 22.05
      firefox-pgo = if lib.versionAtLeast lib.trivial.version "22.05" then final.firefox else final.firefox-bin;

      jetbrains = let
        mkUnset = pkg: pkg.overrideAttrs (old: {
          postFixup = old.postFixup or "" + ''
            # Needed for enter nix shell plugin to change the IDE's env fully
            wrapProgram $out/bin/${pkg.meta.mainProgram} --unset DESKTOP_STARTUP_ID
          '';
        });
        isJBIDE = pkg: lib.isDerivation pkg && !lib.hasPrefix "jetbrains-jdk" pkg.name;
      in lib.mapAttrs (n: v: if isJBIDE v then mkUnset v else v) prev.jetbrains;

      networkmanager-openconnect = final.empty // {
        networkManagerPlugin = "openconnect";
      };
    })
  ];
}
