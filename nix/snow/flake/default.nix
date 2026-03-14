{
  this,
  inputs,
  systems,
  ...
}: let
  inherit
    (builtins)
    attrNames
    concatStringsSep
    filter
    length
    removeAttrs
    warn
    ;

  inherit (inputs.nixpkgs) lib;
in {
  # snow.flake
  flake = flakeInputs: root: let
    snowflake = lib.evalModules {
      class = "snowflake";
      specialArgs = let
        reservedInputs = {
          inherit (this) snow;
          inherit systems root;
          inputs = flakeInputs;
        };

        warnIfReserved = let
          getReservedNames = names:
            reservedInputs
            |> attrNames
            |> filter (name: names?${name});

          reservedNames =
            flakeInputs
            |> attrNames
            |> getReservedNames;
        in
          (length reservedNames == 0)
          || warn ''
            [snow] Your `flake.nix` declares inputs using reserved names!
            [snow] These will be accessible only via `inputs.''${NAME}`
            [snow] Please rename the following:
            [snow]   ${concatStringsSep reservedNames ", "}
          ''
          true;
      in
        assert warnIfReserved;
          flakeInputs
          // reservedInputs
          # XXX: TODO:
          # |> (x: builtins.removeAttrs x ["self" "nodes"]);
          |> (x: removeAttrs x ["self"]);

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
