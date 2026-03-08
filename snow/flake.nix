{
  description = "Cerulean CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    systems.url = "github:nix-systems/default";

    fenix.url = "github:nix-community/fenix";
    fenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    systems = import inputs.systems;

    mkPkgs = system: repo:
      import repo {
        inherit system;
        allowUnfree = false;
        allowBroken = false;
        overlays = builtins.attrValues self.overlays or {};
      };

    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system (mkPkgs system nixpkgs));
  in {
    overlays.default = final: prev: {
      libclang = prev.llvmPackages_21.libclang;

      # ttywire = pkgs.rustPlatform.buildRustPackage {
      #   pname = "cerulean";
      #   version = "0.1.0";
      #   src = ./.;
      #
      #   cargoHash = "sha256-NxFdFCuB456uBeVeqT2bsRtBrIoLdijBaga7VB9KPF8=";
      #
      #   # runtime dependencies (propagated out of derivation)
      #   buildInputs = with pkgs; [
      #     boehmgc.dev
      #     nix.dev
      #   ];
      #
      #   # build-time/shellHook dependencies (not propagates)
      #   nativeBuildInputs = with pkgs; [
      #     pkg-config
      #   ];
      #
      #   meta = with lib; {
      #     description = "Cerulean CLI";
      #     homepage = "https://github.com/cry128/cerulean";
      #     license = lib.licenses.asl20;
      #     maintainers = with maintainers; [
      #       cry64
      #     ];
      #   };
      # };
    };

    checks = self.packages or {};

    # packages = forAllSystems (
    #   system: pkgs: rec {
    #     inherit (pkgs) ttywire;
    #     default = ttywire;
    #   }
    # );

    devShells = forAllSystems (
      system: pkgs: {
        default = pkgs.mkShell rec {
          shell = "${pkgs.bash}/bin/bash";
          strictDeps = true;

          packages = with pkgs; [
            cargo
            rustc
            inputs.fenix.packages.${system}.complete.rustfmt
          ];

          # packages we should be able to link against
          buildInputs = with pkgs; [
            boehmgc.dev
            nix.dev
          ];

          # packages we run at build time / shellHook
          nativeBuildInputs = with pkgs; [
            pkg-config
            rustPlatform.bindgenHook
          ];

          LD_LIBRARY_PATH = "$LD_LIBRARY_PATH:${builtins.toString (pkgs.lib.makeLibraryPath buildInputs)}";
        };
      }
    );
  };
}
