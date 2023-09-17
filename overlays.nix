{ lib, config, ... }:

let
  this = config.custom.overlays;
  inherit (lib) mkEnableOption mkIf;
in

{
  options.custom.overlays = {
    enable = mkEnableOption "my custom overlays";

    mutterPatch = mkEnableOption "mutter patch allowing >144Hz in GDM";
  };

  config.nixpkgs.overlays = mkIf this.enable [
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

      gnome = prev.gnome.overrideScope' (gfinal: gprev: {
        mutter = gprev.mutter.overrideDerivation (old: {
          patches = old.patches ++ [
            (final.fetchpatch {
              url = "https://gitlab.gnome.org/GNOME/mutter/-/merge_requests/3120.patch";
              hash = "sha256-nOHuc9Z9EbountH4Hf+fxjyhQwaCnsz78eoJ5UapP1A=";
            })
          ];
        });
      });

      youtube-dl = (
        if final ? yt-dlp
        then final.yt-dlp.override { withAlias = true; }
        else prev.youtube-dl
      );
    })
  ];
}
