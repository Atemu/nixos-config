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

      mangohud = (prev.mangohud.override { libXNVCtrl = null; }).overrideAttrs (old: {
        mesonFlags = old.mesonFlags ++ [
          "-Dwith_xnvctrl=disabled"
        ];
      });

      mesa_22_2 = prev.mesa.overrideAttrs (old: rec {
        version = "22.2.1";

        src = prev.fetchurl {
          url = "https://mesa.freedesktop.org/archive/mesa-${version}.tar.xz";
          sha256 = "sha256-AHm+rAoz9F5+CuxZ5pE+r7xCaKPx4uMwAXRASU+RsTw=";
        };

        patches = with builtins; let
          isGoodPatch = item: let
            isStacksizePatch = isAttrs item && item.name == "musl-stacksize.patch";
            isOldCachPatch = isPath item && baseNameOf item == "disk_cache-include-dri-driver-path-in-cache-key.patch";
          in !isStacksizePatch && !isOldCachPatch;
        in (filter isGoodPatch old.patches) ++ [
          # Rebased version of the previous one
          ./disk_cache-include-dri-driver-path-in-cache-key.patch

          (final.fetchpatch {
            url = "https://gitlab.freedesktop.org/mesa/mesa/uploads/abb792ee6830a765789b15cbec4b7c59/0001-radeonsi-vcn-enc-fix-issue-with-width-when-encoding-.patch";
            hash = "sha256-j2/WlGUeLR7AQvWMvF4Cvn+/Lvz3FhnNshAi0p35mjY=";
          })
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
