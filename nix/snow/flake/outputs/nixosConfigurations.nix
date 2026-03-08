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
    nixosConfigurations = mapNodes nodes (
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
        ceruleanArgs = {
          inherit systems root base nodes node;
          inherit (node) system;
          inherit (this) snow;
          hostname = name;

          _cerulean = {
            inherit inputs userArgs ceruleanArgs homeManager;
            specialArgs = userArgs // ceruleanArgs;
          };
        };
        specialArgs = assert (userArgs
          |> attrNames
          |> all (argName:
            ! ceruleanArgs ? argName
            || abort ''
              `specialArgs` are like super important to Cerulean my love... </3
              But `args.${argName}` is a reserved argument name :(
            ''));
          ceruleanArgs._cerulean.specialArgs;
      in
        lib.nixosSystem {
          inherit (node) system;
          inherit specialArgs;
          modules =
            [
              self.nixosModules.default
              (this.findImport /${root}/hosts/${name})
            ]
            ++ (groupModules root)
            ++ node.modules
            ++ nodes.modules;
        }
    );

