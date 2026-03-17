{
  _snowFlake,
  snow,
  config,
  systems,
  root,
  ...
}: let
  inherit
    (builtins)
    all
    attrNames
    warn
    ;

  inherit
    (config)
    nodes
    ;
in {
  outputs.nixosConfigurations = let
    groups = snow.lib.parseGroupDecls root config.nodes.groups;
  in
    snow.lib.mapNodes nodes (
      {
        base,
        lib,
        name,
        node,
        ...
      }: let
        nodeGroups =
          (node.groups groups)
          |> snow.lib.resolveGroupsInheritance
          |> snow.lib.groupModules;

        homeManager =
          if node.homeManager != null
          then node.homeManager
          else if nodes.homeManager != null
          then nodes.homeManager
          else
            warn ''
              [snowflake] Neither `nodes.homeManager` nor `nodes.nodes.${name}.homeManager` were specified!
              [snowflake] home-manager will NOT be used! User configuration will be ignored!
            ''
            null;

        userArgs = nodes.args // node.args;
        snowArgs = {
          inherit systems snow root base nodes node;
          inherit (node) system;
          hostname = name;

          _snow = {
            inherit (_snowFlake) inputs;
            inherit userArgs snowArgs homeManager;
            specialArgs = userArgs // snowArgs;
          };
        };
        specialArgs = assert (userArgs
          |> attrNames
          |> all (argName:
            ! snowArgs ? argName
            || abort ''
              `specialArgs` are like super important to Snow my love... </3
              But `args.${argName}` is a reserved argument name :(
            ''));
          snowArgs._snow.specialArgs;
      in
        lib.nixosSystem {
          inherit (node) system;
          inherit specialArgs;
          modules =
            [
              _snowFlake.self.nixosModules.default
              (snow.lib.findImport /${root}/hosts/${name})
            ]
            ++ nodeGroups
            ++ node.modules
            ++ nodes.modules;
        }
    );
}
