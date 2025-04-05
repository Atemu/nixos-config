{
  lib,
  config,
  pkgs,
  utils,
  ...
}:
# This is an abstract interface to interact with secrets. It does not implement
# anything and must be implemented either by another module or, as it currently
# stands, by putting the files into the correct places manually.
let
  this = config.custom.secrets;
  verifier = pkgs.callPackage ./verifier/package.nix { };
in

{
  options.custom.secrets = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, config, ... }:
        {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "The file name of the secret";
              default = name;
            };
            directory = lib.mkOption {
              default = "/var/secrets";
              apply = lib.removeSuffix "/";
              description = "The directory in which the secret files are placed";
            };
            path = lib.mkOption {
              description = "The path where the secret will be accessible at runtime";
              type = lib.types.path;
              default = "${config.directory}/${config.name}";
            };
            user = lib.mkOption {
              default = "root";
              type = lib.types.str;
            };
            group = lib.mkOption {
              default = "root";
              type = lib.types.str;
            };
            mode = lib.mkOption {
              default = "0400";
              type = lib.types.str;
            };
          };
        }
      )
    );
    default = { };
  };

  config = lib.mkIf (this != { }) {
    # TODO one service for each secret
    systemd.services =
      this
      |> lib.mapAttrs' (
        name: secret:
        lib.nameValuePair "secrets-verifier-${utils.escapeSystemdPath name}" {
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            ExecStart = "${lib.getExe verifier} ${pkgs.writers.writeJSON "secrets.json" { ${name} = secret; }}";
          };
        }
      );
  };
}
