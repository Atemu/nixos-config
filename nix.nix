{ stdenv, nixStable, nixUnstable, lib }:

stdenv.mkDerivation {
  inherit (nixUnstable) pname version;
  src = nixUnstable;
  installPhase = ''
    cp -as $src $out
    chmod -R +rw $out

    mv $out/bin/nix $out/bin/nixUnstable
    ln -s nixUnstable $out/bin/nixFlakes
    for cmd in $out/bin/nix-* ; do ln -sf nixUnstable "$cmd" ; done

    ln -s ${nixStable}/bin/nix $out/bin/nixStable
    ln -s nixStable $out/bin/nix

    cd $out/share/bash-completion/completions/
    cp nix nixUnstable
    cp nix nixFlakes
    rm nix
    substituteInPlace nixUnstable --replace " nix" " nixUnstable"
    substituteInPlace nixFlakes --replace " nix" " nixFlakes"
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
