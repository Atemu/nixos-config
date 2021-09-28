{ ... }:

{
  config.lib.custom = {
    # Makes a by-uuid device out of UUID
    mkUuid = uuid: "/dev/disk/by-uuid/${uuid}";
  };
}
