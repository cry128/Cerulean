# # Copyright 2025-2026 _cry64 (Emile Clark-Boman)
# #
# # Licensed under the Apache License, Version 2.0 (the "License");
# # you may not use this file except in compliance with the License.
# # You may obtain a copy of the License at
# #
# #    http://www.apache.org/licenses/LICENSE-2.0
# #
# # Unless required by applicable law or agreed to in writing, software
# # distributed under the License is distributed on an "AS IS" BASIS,
# # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# # See the License for the specific language governing permissions and
# # limitations under the License.
{nt, ...}: let
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

  rootGroupName = "all";
in {
  parseGroupsDecl = groups: let
    validGroup = g:
      isAttrs g
      || throw ''
        Snow node groups must be provided as attribute sets, got "${typeOf g}" instead!
        Ensure all the group definitions are attribute sets under your call to `snow.flake`.
        NOTE: Groups can be accessed via `self.groups.PATH.TO.YOUR.GROUP`
      '';
    delegate = parent: gName: g: let
      result =
        (g
          // {
            _name = gName;
            _parent = parent;
          })
        |> mapAttrs (name: value:
          if elem name ["_name" "_parent"]
          # ignore metadata fields
          then value
          else assert validGroup value; (delegate result name value));
    in
      result;
  in
    assert validGroup groups;
      delegate null rootGroupName groups;

  getGroupModules = root: groups:
  # ensure root group is always added
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
    # find import location
    |> map (group: nt.findImport /${root}/groups/${group._name})
    # filter by uniqueness
    |> nt.prim.unique
    # ignore missing groups
    |> filter pathExists;
}
