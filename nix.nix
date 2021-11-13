{ stdenv, nix_2_3, nixStable, lib }:

stdenv.mkDerivation {
  inherit (nixStable) pname version;
  src = nixStable;
  installPhase = ''
    # Symlink-copy of nixStable
    cp -as $src $out
    chmod -R +rw $out

    cd $out/bin
    mv nix nixStable
    ln -s nixStable nixFlakes

    # All nix-* commands need to point at nixStable now (it's a multi-call binary)
    for cmd in nix-* ; do ln -sf nixStable "$cmd" ; done

    # Provide old nix as nix_2_3
    ln -s ${nix_2_3}/bin/nix nix_2_3
    # nix needs to be the old one for nix-bash-completions (and my muscle memory) to work
    ln -s nix_2_3 nix
    cd -

    # Make nixStable's built-in bash-completions work for the new binary names
    cd $out/share/bash-completion/completions/
    cp nix nixStable
    cp nix nixFlakes
    # We need to replace the command names to be completed with the new ones
    substituteInPlace nixStable --replace " nix" " nixStable"
    substituteInPlace nixFlakes --replace " nix" " nixFlakes"
    # Don't try to complete the nix binary anymore, it's old Nix now and would conflict nix-bash-completions
    rm nix
    cd -
  '';

  meta = nixStable.meta // {
    description = "My custom nix_2_3 nixStable hybrid";
    longDescription = ''
      My custom Nix with the `nix` command from nix_2_3 and everything else from nixStable.

      The new `nix` is available via `nixUnstble` or `nixFlakes`. Bash completions work for these.

      Since `nix` is still the old one, nix-bash-completions also work just fine.
    '';
    maintainers = [ lib.maintainers.atemu ];
  };
}
