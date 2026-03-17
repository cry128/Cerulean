# Copyright 2025-2026 _cry64 (Emile Clark-Boman)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
{
  _snowFlake,
  lib,
  specialArgs,
  ...
}: {
  options.nodes = let
    inherit
      (lib)
      mkOption
      types
      ;
  in
    mkOption {
      description = ''
        Snowflake node declarations.
      '';
      type = types.submoduleWith {
        inherit specialArgs;

        modules = [
          ./nodes.nix
        ];
      };
    };

  config = {
    nodes = {
      base = _snowFlake.inputs.nixpkgs;
    };
  };
}
