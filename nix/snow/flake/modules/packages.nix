{
  lib,
  snow,
  ...
}: let
  inherit
    (lib)
    mkOption
    types
    ;

  inherit
    (snow.lib)
    mkPerSystemFlakeOutput
    ;
in
  mkPerSystemFlakeOutput {
    name = "packages";
    option = mkOption {
      type = types.lazyAttrsOf types.package;
      default = {};
      description = ''
        An attribute set of packages to be built by [`nix build`](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-build.html).

        `nix build .#<name>` will build `packages.<name>`.
      '';
    };
    file = ./packages.nix;
  }
