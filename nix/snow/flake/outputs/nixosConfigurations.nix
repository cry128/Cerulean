# {
#   _module = { ... };
#   _type = "configuration";
#   class = null;
#   config = { ... };
#   extendModules = «lambda extendModules @ /nix/store/9hfp0agnm43kz72l5lpfn9var5p0x2fa-source/lib/modules.nix:340:9»;
#   graph = [ ... ];
#   options = { ... };
#   type = { ... };
# }
{
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
  outputs.nixosConfigurations = mapNodes nodes (
    {
      base,
      lib,
      name,
      node,
      groupModules,
      ...
    }: let
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
          inherit inputs userArgs snowArgs homeManager;
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
            snow.nixosModules.default
            (snow.findImport /${root}/hosts/${name})
          ]
          ++ (groupModules root)
          ++ node.modules
          ++ nodes.modules;
      }
  );
}
