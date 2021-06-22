{ stdenv, nixStable, nixUnstable, lib }:

stdenv.mkDerivation {
  inherit (nixUnstable) pname version;
  src = nixUnstable;
  installPhase = ''
    # Symlink-copy of nixUnstable
    cp -as $src $out
    chmod -R +rw $out

    mv $out/bin/nix $out/bin/nixUnstable
    ln -s nixUnstable $out/bin/nixFlakes

    # All nix-* commands need to point at nixUnstable now (it's a multi-call binary)
    for cmd in $out/bin/nix-* ; do ln -sf nixUnstable "$cmd" ; done

    # Provide old nix as nixStable
    ln -s ${nixStable}/bin/nix $out/bin/nixStable
    # nix needs to be the old one for nix-bash-completions (and my muscle memory) to work
    ln -s nixStable $out/bin/nix

    # Make nixUnstable's built-in bash-completions work for the new binary names
    cd $out/share/bash-completion/completions/
    cp nix nixUnstable
    cp nix nixFlakes
    # We need to replace the command names to be completed with the new ones
    substituteInPlace nixUnstable --replace " nix" " nixUnstable"
    substituteInPlace nixFlakes --replace " nix" " nixFlakes"
    # Don't try to complete the nix binary anymore, it's old Nix now and would conflict nix-bash-completions
    rm nix
    cd -
  '';

  meta = nixUnstable.meta // {
    description = "My custom nixStable nixUnstable hybrid";
    longDescription = ''
      My custom Nix with the `nix` command from nixStable and everything else from nixUnstable.

      The new `nix` is available via `nixUnstble` or `nixFlakes`. Bash completions work for these.

      Since `nix` is still the old one, nix-bash-completions also work just fine.
    '';
    maintainers = [ lib.maintainers.atemu ];
  };
}
