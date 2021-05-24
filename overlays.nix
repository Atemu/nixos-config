{
  nixpkgs.overlays = [
    (next: prev: {
      nix = next.nixUnstable.overrideAttrs (old: {
        postInstallCheck = ''
          mv $out/bin/nix $out/bin/nixUnstable
          ln $out/bin/nixUnstable $out/bin/nixFlakes
          for cmd in $out/bin/nix-* ; do ln -sf nixUnstable "$cmd" ; done

          ln -s ${next.nixStable}/bin/nix $out/bin/nixStable
          ln -s $out/bin/nixStable $out/bin/nix

          mv $out/share/bash-completion/completions/nix $out/share/bash-completion/completions/nixUnstable
          cp -a $out/share/bash-completion/completions/nixUnstable $out/share/bash-completion/completions/nixFlakes
          substituteInPlace $out/share/bash-completion/completions/nixUnstable --replace " nix" " nixUnstable"
          substituteInPlace $out/share/bash-completion/completions/nixFlakes --replace " nix" " nixFlakes"
        '';
        doCheck = false;
      });
    })
  ];
}
