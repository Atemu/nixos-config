{ stdenv, nix_2_3, nixStable, lib }:

stdenv.mkDerivation {
  inherit (nixStable) pname version;
  src = nixStable;
  installPhase = ''
    # Symlink-copy of nixStable
    cp -as $src $out
    chmod -R +rw $out

    pushd $out/bin
    mv nix nix3
    ln -s nix3 nix

    # All nix-* commands need to point at nixStable now (it's a multi-call binary)
    for cmd in nix-* ; do ln -sf nix3 "$cmd" ; done

    # Provide old nix as nix2
    ln -s ${nix_2_3}/bin/nix nix2
    popd
  '';

  meta = nixStable.meta // {
    description = "My custom nix_2_3 nixStable hybrid";
    longDescription = ''
      My custom Nix with the `nix` command from nix_2_3 and everything else from nixStable.

      The new `nix` is also available via `nix3` or `nixFlakes`. Bash completions work for these.
    '';
    maintainers = [ lib.maintainers.atemu ];
  };
}
