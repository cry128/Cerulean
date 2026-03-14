{
  inputs,
  lib,
  ...
}: let
  inherit
    (lib)
    mkOption
    types
    ;

  # A best effort, lenient estimate. Please use a recent nixpkgs lib if you
  # override it at all.
  minVersion = "23.05pre-git";

  isNixpkgsValidVersion = let
    revInfo = lib.optional (inputs.nixpkgs?rev) " (nixpkgs-lib.rev: ${inputs.nixpkgs.rev})";
  in
    (builtins.compareVersions lib.version minVersion < 0)
    || abort ''
      The nixpkgs dependency of snow was overridden but is too old.
      The minimum supported version of nixpkgs-lib is ${minVersion},
      but the actual version is ${lib.version}${revInfo}.
    '';
in
  assert isNixpkgsValidVersion; {
    # Helper function for defining a per-system option that
    # gets transposed by the usual flake system logic to a
    # top-level outputs attribute.
    mkPerSystemFlakeOutput = {
      name,
      option,
      file,
    }: {
      _file = file;

      options = {
        outputs.${name} = mkOption {
          type = types.attrsWith {
            elemType = option.type;
            lazy = true;
            placeholder = "system";
          };
          default = {};
          description = ''
            See {option}`perSystem.${name}` for description and examples.
          '';
        };
      };
    };
  }
