# This function loads `toolchain-*.nix` files in this folder
# and imports them. Each `toolchain-*.nix` file contains a
# list of `devenv` modules.
# The function returns all toolchains in an attrset.
{
  lib,
  pkgs,
  namespace,
  ...
}@args:
let
  language = "generic";
  toolchains = lib.${namespace}.toolchain.import ./. args;
in
toolchains // rec {
  default = toolchains.${language};
  ci = default;
}
