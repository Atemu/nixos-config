{ lib, config, ... }:

let
  this = config.custom.overlays;
  inherit (lib) mkEnableOption mkIf;
in

{
  options.custom.overlays = {
    enable = mkEnableOption "my custom overlays";
  };

  config.nixpkgs.overlays = mkIf this.enable [
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

      mangohud = (prev.mangohud.override { libXNVCtrl = null; }).overrideAttrs (old: {
        mesonFlags = old.mesonFlags ++ [
          "-Dwith_xnvctrl=disabled"
        ];
      });

      nixd = prev.nixd.overrideAttrs (old: {
        patches = old.patches or [ ] ++ [
          (final.fetchpatch2 {
            # https://github.com/nix-community/nixd/pull/502
            url = "https://github.com/nix-community/nixd/commit/918d312374bb4e35d34260e3dc22b354ba41ca4e.patch";
            hash = "sha256-qeBIGwoR1NKwN/56n4s+pg98Blw/Dj/TzW2rN+5EoDA=";
          })
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
