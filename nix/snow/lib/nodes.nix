{
  this,
  nt,
  ...
}: let
  inherit
    (builtins)
    concatLists
    elem
    filter
    isAttrs
    mapAttrs
    pathExists
    typeOf
    ;

  inherit (nt.prim) uniq;

  rootGroupName = "all";
in {
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

        inherit (node) groups;
      });

  groupModules = map (group: group._module);

  parseGroupDecls = root: groupDecls: let
    validGroup = g:
      isAttrs g
      || throw ''
        Snow node groups must be provided as attribute sets, got "${typeOf g}" instead!
        Ensure all the group definitions are attribute sets under your call to `snow.flake`.
      '';
    delegate = parent: gName: g: let
      result =
        (g
          // {
            _name = gName;
            _parent = parent;
            _module = this.lib.findImport /${root}/groups/${gName};
          })
        |> mapAttrs (name: value:
          if elem name ["_name" "_parent" "_module"]
          # ignore metadata fields
          then value
          else assert validGroup value; (delegate result name value));
    in
      result;
  in
    assert validGroup groupDecls;
      delegate null rootGroupName groupDecls;

  resolveGroupsInheritance = groups:
    groups
    # add all inherited groups via _parent
    |> map (let
      delegate = g:
        if g._parent == null
        then [g]
        else [g] ++ delegate (g._parent);
    in
      delegate)
    # flatten recursion result
    |> concatLists
    # ignore missing groups
    |> filter (group: pathExists group._module)
    # filter by uniqueness
    |> uniq;
}
