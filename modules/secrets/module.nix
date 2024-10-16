{ lib, ... }:

# This is an abstract interface to interact with secrets. It does not implement
# anything and must be implemented either by another module or, as it currently
# stands, by putting the files into the correct places manually.
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
          };
        }
      )
    );
    default = { };
  };
}
