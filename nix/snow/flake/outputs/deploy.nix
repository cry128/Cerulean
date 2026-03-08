    deploy.nodes = mapNodes nodes ({
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

      nixosFor = system: inputs.deploy-rs.lib.${system}.activate.nixos;
    in {
      hostname =
        if ssh.host != null
        then ssh.host
        else "";

      profilesOrder = ["default"]; # profiles priority
      profiles.default = {
        path = nixosFor node.system nixosConfigurations.${name};

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
            if elem "-p" ssh.opts
            then []
            else ["-p" (toString ssh.port)]
          )
          ++ (
            if elem "-A" ssh.opts
            then []
            else ["-A"]
          );
      };
    });

