{ lib, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      customNix = final.callPackage ./nix.nix {
        nixStable = final.nix;
      };

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

      nix = let
        nixVersions = final.nixVersions or final; # 21.11 doesn't have nixVersions, use pkgs' aliases instead
      in nixVersions.nix_2_9 or nixVersions.nix_2_8 or nixVersions.nix_2_7 or nixVersions.nix_2_6 or nixVersions.nix_2_4 or nixVersions.nixUnstable;

      mangohud = (prev.mangohud.override { libXNVCtrl = null; }).overrideAttrs (old: {
        mesonFlags = old.mesonFlags ++ [
          "-Dwith_xnvctrl=disabled"
        ];
      });

      mesa_22_2 = prev.mesa.overrideAttrs (old: rec {
        version = "22.2.0-rc3";

        src = prev.fetchurl {
          url = "https://mesa.freedesktop.org/archive/mesa-${version}.tar.xz";
          sha256 = "sha256-2zkjB6Avl7eoI3gJ4oticwY1aisnu5Eb+fQ0S2YxPjk=";
        };

        patches = with builtins; let
          isGoodPatch = item: let
            isStacksizePatch = isAttrs item && item.name == "musl-stacksize.patch";
            isOldCachPatch = isPath item && baseNameOf item == "disk_cache-include-dri-driver-path-in-cache-key.patch";
          in !isStacksizePatch && !isOldCachPatch;
        in (filter isGoodPatch old.patches) ++ [
          # Rebased version of the previous one
          ./disk_cache-include-dri-driver-path-in-cache-key.patch
        ];

        nativeBuildInputs = old.nativeBuildInputs ++[
          prev.glslang
        ];

        mesonFlags = old.mesonFlags ++ [
          "-Dvideo-codecs=vc1dec,h264dec,h264enc,h265dec,h265enc"
        ];
      });

      youtube-dl = (
        if final ? yt-dlp
        then final.yt-dlp.override { withAlias = true; }
        else prev.youtube-dl
      );
    })
  ];
}
