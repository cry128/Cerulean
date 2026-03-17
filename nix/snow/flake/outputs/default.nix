{...}: {
  imports = [
    ./outputs.nix

    ./apps.nix
    ./checks.nix
    ./devShells.nix
    ./formatter.nix
    ./legacyPackages.nix
    ./nixosConfigurations.nix
    ./nixosModules.nix
    ./overlays.nix
    ./packages.nix
  ];
}
