echo '{
  hostName = "";
  productName = "";
}' > $(echo $(dirname $(realpath $0))/meta.nix)
