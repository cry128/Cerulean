{...}: {
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    nix-bindings-rust.nixPackage = pkgs.nix;

    # declare projects
    nci.projects."cerulean-project" = {
      path = ./.;
      # export all crates (packages and devshell) in flake outputs
      # alternatively you can access the outputs and export them yourself
      export = true;

      depsDrvConfig = {
        imports = [config.nix-bindings-rust.nciBuildConfig];
      };
    };
    # configure crates
    nci.crates."cerulean" = rec {
      # profiles.release = rec {
      default = true;
      runTests = true;

      drvConfig =
        depsDrvConfig
        // {
          env.CARGO_TERM_VERBOSE = "true";
        };

      depsDrvConfig = rec {
        env.LD_LIBRARY_PATH = "$LD_LIBRARY_PATH:${builtins.toString (pkgs.lib.makeLibraryPath mkDerivation.buildInputs)}";

        mkDerivation = {
          buildInputs = with pkgs; [
            boehmgc.dev
            nix.dev
          ];
          nativeBuildInputs = with pkgs; [
            pkg-config
            rustPlatform.bindgenHook
          ];
        };
      };
      # };
    };
  };
}
