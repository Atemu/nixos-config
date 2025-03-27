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

      # Patched for half-way sane systemd-run usage
      rofi-wayland-custom = pkgs.rofi-wayland.override {
        rofi-unwrapped = pkgs.rofi-wayland-unwrapped.overrideAttrs (old: rec {
          version = "1.7.5+wayland3";
          src = pkgs.fetchFromGitHub {
            owner = "lbonn";
            repo = "rofi";
            tag = version;
            fetchSubmodules = true;
            hash = "sha256-pKxraG3fhBh53m+bLPzCigRr6dBcH/A9vbdf67CO2d8=";
          };
          patches = old.patches or [ ] ++ [
            # Makes {app_id} available in -run-command.
            # https://github.com/davatorium/rofi/pull/2048#issuecomment-2466841262
            ./rofi-desktop-app-id.patch
          ];
        });
      };
    })
  ];
}
