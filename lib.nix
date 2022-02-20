{ ... }:

{
  config.lib.custom = {
    # Makes a by-uuid device out of UUID
    mkUuid = uuid: "/dev/disk/by-uuid/${uuid}";

    # Makes a by-label device out of label
    mkLabel = label: "/dev/disk/by-label/${label}";
  };
}
