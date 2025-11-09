{
  lib,
  config,
  pkgs,
  ...
}:

let
  this = config.custom.overlays;
in

{
  options.custom.overlays = {
    enable = lib.mkEnableOption "my custom overlays";
  };

  config.nixpkgs.overlays = lib.mkIf this.enable [
    (final: prev: {
      bs-manager = prev.bs-manager.overrideAttrs (
        {
          patches ? [ ],
          ...
        }:
        {
          patches = patches ++ [
            (final.fetchpatch {
              url = "https://patch-diff.githubusercontent.com/raw/Zagrios/bs-manager/pull/943.patch";
              hash = "sha256-7SUSAS//7BUwWQBzWmf7bko6gsbnUjhBr4xaDmFuIHo=";
            })
          ];
        }
      );
      colmena =
        if lib.versionAtLeast lib.trivial.version "24.11" then
          (prev.colmena.override {
            nix = final.lix;
          }).overrideAttrs
            (
              {
                postPatch ? "",
                ...
              }:
              {
                # https://github.com/zhaofengli/colmena/pull/268/
                postPatch =
                  postPatch
                  + ''
                    substituteInPlace src/command/repl.rs \
                      --replace-fail "--experimental-features" "--extra-experimental-features"
                  '';
              }
            )
        else
          prev.colmena;

      # A firefox with PGO, enabled in regular from-source firefox since 22.05
      firefox-pgo =
        if lib.versionAtLeast lib.trivial.version "22.05" then final.firefox else final.firefox-bin;

      jetbrains =
        let
          mkUnset =
            pkg:
            pkg.overrideAttrs (old: {
              postFixup =
                old.postFixup or ""
                + ''
                  # Needed for enter nix shell plugin to change the IDE's env fully
                  wrapProgram $out/bin/${pkg.meta.mainProgram} --unset DESKTOP_STARTUP_ID
                '';
            });
          isJBIDE = pkg: lib.isDerivation pkg && !lib.hasPrefix "jetbrains-jdk" pkg.name;
        in
        lib.mapAttrs (n: v: if isJBIDE v then mkUnset v else v) prev.jetbrains;

      networkmanager-openconnect = final.empty // {
        networkManagerPlugin = "openconnect";
      };

      # Pulls in texliveMedium into the build closure for docs that I don't care
      # about. It wasn't cached for some reason and I was suddenly pulling in
      # texlive. It and qmk which depends on it are quick builds, so just always
      # build without docs so that this never happens.
      avrdude = prev.avrdude.override { docSupport = false; };
    })
  ];
}
