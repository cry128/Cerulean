{
  description = "Cerulean CLI";

  inputs = {
    systems.url = "github:nix-systems/default-linux";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nci = {
      url = "github:90-008/nix-cargo-integration";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-bindings-rust.url = "github:nixops4/nix-bindings-rust";

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    parts,
    nci,
    nix-bindings-rust,
    ...
  }:
    parts.lib.mkFlake {inherit inputs;} {
      imports = [
        parts.flakeModules.easyOverlay
        nci.flakeModule
        nix-bindings-rust.modules.flake.default
        ./crates.nix
      ];

      systems = import inputs.systems;

      perSystem = {
        config,
        pkgs,
        ...
      }: let
        outputs = config.nci.outputs;
      in {
        overlayAttrs = {
          cerulean = outputs."cerulean".packages.default;
        };

        # nix-bindings-rust.nixPackage = pkgs.nix;

        devShells.default = outputs."cerulean-project".devShell;

        packages = rec {
          inherit (pkgs) cerulean;
          default = cerulean;
        };
      };
    };
}
