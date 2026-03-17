{
  config,
  _snowFlake,
  ...
}: {
  outputs.checks =
    _snowFlake.inputs.deploy-rs.lib
    |> builtins.mapAttrs (system: deployLib:
      deployLib.deployChecks config.outputs.deploy);
}
