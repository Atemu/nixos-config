{ lib, ... }:

with builtins;
with lib;

# Set of all my configs
let
  contents = readDir ./.;
  dirs = filterAttrs (n: v: v == "directory") contents;
  set = mapAttrs (n: v: import (./. + "/${n}")) dirs;
in set
