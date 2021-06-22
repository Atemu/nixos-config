{ lib, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      nix = final.callPackage ./nix.nix { };

      jetbrains = let
        mkUnset = pkg: pkg.overrideAttrs (old: {
          postFixup = old.postFixup or "" + ''
            # Needed for enter nix shell plugin to change the IDE's env fully
            wrapProgram $out/bin/${pkg.meta.mainProgram} --unset DESKTOP_STARTUP_ID
          '';
        });
        isJBIDE = pkg: lib.isDerivation pkg && !lib.hasPrefix "jetbrains-jdk" pkg.name;
      in lib.mapAttrs (n: v: if isJBIDE v then mkUnset v else v) prev.jetbrains;
    })
  ];
}
