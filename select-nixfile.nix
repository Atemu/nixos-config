selection:
if (builtins.readDir ../.) ? ".isnixfiles" then
  ../${selection}
else
  builtins.trace "warning: nixfiles not present, using ${selection} from $NIX_PATH!" (
    builtins.findFile builtins.nixPath selection
  )
