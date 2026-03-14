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
    name = "checks";
    option = mkOption {
      type = types.lazyAttrsOf types.package;
      default = {};
      description = ''
        Derivations to be built by [`nix flake check`](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake-check.html).
      '';
    };
    file = ./checks.nix;
  }
