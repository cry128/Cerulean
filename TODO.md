## Next
- [ ] secrets management pleaseeeeeeeeeeeeeeeeeeeeee

- [ ] figure out how Cerulean could aid CI/CD (ie hydra + nix-unit)
      you can
  https://github.com/NotAShelf/nix-bindings/tree/main/nix-bindings
  https://notashelf.github.io/nix-bindings/nix_bindings/#structs
  https://github.com/nixops4/nix-bindings-rust
  https://nix.dev/manual/nix/2.34/c-api.html

- [ ] move home management to `~/.snow/flake.nix`, then the `/etc/snow/flake.nix`
      will only contain base definitions for the home

- [ ] write a key management system that supports activation time, run time, and build time
    https://docs.aws.amazon.com/kms/latest/developerguide/overview.html

- [ ] formalize how the snow flake system compiles outputs, this would remove the need for `mapNodes`
- [ ] groups should allow you to set node configuration defaults

- [ ] add `options.experimental` for snowflake
- [ ] add `legacyImports` support

- [ ] support hs system per dir, ie hosts/<name>/overlays or hosts/<name>/nixpkgs.nix

## Queued
- [ ] per node home configuration is a lil jank rn

- [ ] deploy port should default to the first port given to `services.openssh`

- [ ] create an alternative to nixos-install called cerulean-install that
      allows people to easily bootstrap new machines (and host it on dobutterfliescry.net)

- [ ] find an alternative to `nix.settings.trusted-users` probably
- [ ] add the ceru-build user, 
- [ ] add support for github:microvm-nix/microvm.nix
- [ ] add support for sops-nix

- [ ] it would be cool to enable/disable groups and hosts
- [ ] find a standard for how nixpkgs.nix can have a different base per group

- [ ] go through all flake inputs (recursively) and ENSURE we remove all duplicates by using follows!!

- [ ] allow multiple privesc methods, the standard is pam_ssh_agent_auth

## Low Priority
- [ ] make an extension to the nix module system (different to mix)
      that allows transformations (ie a stop post config, ie outputs, which
      it then returns instead of config)
- [ ] support `legacyImports` (?)

- [ ] patch microvm so that acpi=off https://github.com/microvm-nix/microvm.nix/commit/b59a26962bb324cc0a134756a323f3e164409b72
      cause otherwise 2GB causes a failure

- [ ] write the cerulean cli


```nix
# REF: foxora
vms = {
  home-assistant = {
    autostart = true;
    # matches in vms/*
    image = "home-assistant";
    options = {
      mem = 2048;
    };
  };
  equinox = {
    image = "home-assistant";
  };
};
```
