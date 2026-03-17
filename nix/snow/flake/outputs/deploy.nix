{
  _snowFlake,
  snow,
  config,
  ...
}: {
  outputs.deploy.nodes = snow.lib.mapNodes config.nodes ({
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

    nixosFor = system: _snowFlake.inputs.deploy-rs.lib.${system}.activate.nixos;
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
