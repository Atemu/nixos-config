# Set of all my configs
let
  contents = builtins.readDir ./.;
  # We don't have filterAttrs here, excluding this file will have to do
  # Perhaps you could filter the tree instead?
  dirs = builtins.removeAttrs contents [ "default.nix" ];
in
builtins.mapAttrs (n: v: import (./. + "/${n}")) dirs
