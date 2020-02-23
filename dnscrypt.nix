{ config, ... }:

{
  # Enable dnscrypt-proxy-2 via a Docker image
  # FIXME: Use the native Nix dnscrypt-proxy-2 module when it's available
  docker-containers.dnscrypt-proxy = {
    image = "atemu12/dnscrypt-proxy-2";
    ports = [ "53:53/udp" ];
    volumes = [ "dnscrypt-blacklist:/blacklist/:ro" ];
  };
  networking.resolvconf.useLocalResolver = true;

}
