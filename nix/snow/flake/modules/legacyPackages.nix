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
    (snow)
    mkPerSystemFlakeOutput
    ;
in
  mkPerSystemFlakeOutput {
    name = "legacyPackages";
    option = mkOption {
      type = types.lazyAttrsOf types.raw;
      default = {};
      description = ''
        Used for nixpkgs packages, also accessible via `nix build .#<name>` [`nix build .#<name>`](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-build.html).
      '';
    };
    file = ./legacyPackages.nix;
  }
