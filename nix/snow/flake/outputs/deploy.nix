{
  _snow,
  config,
  ...
}: let
  inherit
    (builtins)
    mapAttrs
    ;

  mapNodes = nodes: f:
    nodes.nodes
    |> mapAttrs (name: node: let
      # use per-node base or default to nodes' base
      base =
        if node.base != null
        then node.base
        else if nodes.base != null
        then nodes.base
        else
          abort ''
            snow cannot construct nodes node "${name}" without a base package source.
            Ensure `nodes.nodes.*.base` or `nodes.base` is a flake reference to the github:NixOS/nixpkgs repository.
          '';
    in
      f rec {
        inherit name node base;
        inherit (base) lib;

        groups = node.groups (parseGroupsDecl nodes.groups);
        groupModules = root: getGroupModules root groups;
      });
in {
  outputs.deploy.nodes = mapNodes config.nodes ({
    name,
    node,
    ...
  }: let
    inherit
      (node.deploy)
      ssh
      user
      interactiveSudo
      remoteBuild
      rollback
      autoRollback
      magicRollback
      activationTimeout
      confirmTimeout
      ;

    nixosFor = system: _snow.inputs.deploy-rs.lib.${system}.activate.nixos;
  in {
    hostname =
      if ssh.host != null
      then ssh.host
      else "";

    profilesOrder = ["default"]; # profiles priority
    profiles.default = {
      path = nixosFor node.system config.outputs.nixosConfigurations.${name};

      user = user;
      sudo = "sudo -u";
      interactiveSudo = interactiveSudo;

      fastConnection = false;

      autoRollback = autoRollback -> rollback;
      magicRollback = magicRollback -> rollback;
      activationTimeout = activationTimeout;
      confirmTimeout = confirmTimeout;

      remoteBuild = remoteBuild;
      sshUser = ssh.user;
      sshOpts =
        ssh.opts
        ++ (
          if builtins.elem "-p" ssh.opts
          then []
          else ["-p" (toString ssh.port)]
        )
        ++ (
          if builtins.elem "-A" ssh.opts
          then []
          else ["-A"]
        );
    };
  });
}
