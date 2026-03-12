{
  modulesPath,
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (config?isoImage) {
    # TODO: do i really need to import ALL of this?
    imports = [(modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")];

    environment.systemPackages = [
      pkgs.neovim
    ];
  };
}
