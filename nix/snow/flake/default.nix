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
    warn
    ;

  inherit (inputs.nixpkgs) lib;
in {
  # snow.flake
  flake = flakeInputs: root: let
    snowflake = lib.evalModules {
      class = "snowflake";
      specialArgs = let
        reservedSpecialArgs = {
          inherit (this) snow;
          inherit systems root;
          inputs = flakeInputs;
        };

        warnIfReserved = let
          getReservedNames = names:
            reservedSpecialArgs
            |> attrNames
            |> filter (name: names?${name});

          reservedNames =
            flakeInputs
            |> attrNames
            |> getReservedNames;
        in
          (length reservedNames == 0)
          || warn ''
            [snow] Your `flake.nix` declares inputs with reserved names!
            [snow] These will be accessible only via `inputs.''${NAME}`
            [snow] Please rename the following:
            [snow]   ${concatStringsSep reservedNames ", "}
          ''
          true;
      in
        assert warnIfReserved;
          flakeInputs // reservedSpecialArgs;

      modules = [
        ./module.nix
      ];
    };
  in
    snowflake.config.outputs;
}
