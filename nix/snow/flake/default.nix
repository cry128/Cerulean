{
  this,
  inputs,
  systems,
  ...
}: let
  inherit (inputs.nixpkgs) lib;
in {
  # snow.flake
  flake = flakeInputs: root: let
    snowflake = lib.evalModules {
      class = "snowflake";
      # XXX: TODO: abort if inputs contains reserved names
      specialArgs =
        (flakeInputs
          // {
            inherit (this) snow;
            inherit systems root;
            inputs = flakeInputs;
          })
        # XXX: TODO:
        # |> (x: builtins.removeAttrs x ["self" "nodes"]);
        |> (x: builtins.removeAttrs x ["self"]);

      modules = [
        ./module.nix
        ({config, ...}: {
          _module.args = {
            self = config;
            # XXX: TODO:
            # nodes = config.nodes.nodes;
          };
        })
      ];
    };
  in
    snowflake.config.outputs;
}
