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

      nix-bash-completions = prev.nix-bash-completions.overrideAttrs (old: {
        # Override upstream postPatch to still apply to `nix2`
        postPatch = ''
          substituteInPlace _nix --replace 'nix nixos-option' 'nix nixos-option' \
            --replace 'nix)' 'nix)'
        '';
      });

      youtube-dl = (
        if final ? yt-dlp
        then final.yt-dlp.override { withAlias = true; }
        else prev.youtube-dl
      );
    })
  ];
}
