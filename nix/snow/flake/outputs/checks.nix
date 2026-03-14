{
  config,
  _snow,
  ...
}: {
  outputs.checks =
    _snow.inputs.deploy-rs.lib
    |> builtins.mapAttrs (system: deployLib:
      deployLib.deployChecks config.outputs.deploy);
}
