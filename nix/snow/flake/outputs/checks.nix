    checks =
      inputs.deploy-rs.lib
      |> mapAttrs (system: deployLib:
        deployLib.deployChecks deploy);

