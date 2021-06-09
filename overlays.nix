{ lib, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      nix = final.stdenv.mkDerivation {
        inherit (final.nixUnstable) pname version;
        src = final.nixUnstable;
        installPhase = ''
          cp -a $src $out
          chmod -R +rw $out

          mv $out/bin/nix $out/bin/nixUnstable
          ln $out/bin/nixUnstable $out/bin/nixFlakes
          for cmd in $out/bin/nix-* ; do ln -sf nixUnstable "$cmd" ; done

          ln -s ${final.nixStable}/bin/nix $out/bin/nixStable
          ln -s $out/bin/nixStable $out/bin/nix

          mv $out/share/bash-completion/completions/nix $out/share/bash-completion/completions/nixUnstable
          cp -a $out/share/bash-completion/completions/nixUnstable $out/share/bash-completion/completions/nixFlakes
          substituteInPlace $out/share/bash-completion/completions/nixUnstable --replace " nix" " nixUnstable"
          substituteInPlace $out/share/bash-completion/completions/nixFlakes --replace " nix" " nixFlakes"
        '';
        meta = final.nixUnstable.meta // {
          description = "My custom nixStable nixUnstable hybrid";
          longDescription = ''
            My custom Nix with the `nix` command from nixStable and everything else from nixUnstable.

            The new `nix` is available via `nixUnstble` or `nixFlakes`. Bash completions work for these.

            Since `nix` is still the old one, nix-bash-completions also work just fine.
          '';
          maintainers = [ lib.maintainers.atemu ];
        };
      };

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
