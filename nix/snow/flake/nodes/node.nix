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
  lib,
  systems,
  config,
  nodesConfig,
  ...
}: {
  options = let
    inherit
      (lib)
      mkOption
      types
      ;

    flakeRef = types.either types.str types.path;
  in {
    enabled = lib.mkOption {
      type = types.bool;
      default = true;
      example = true;
      description = ''
        Whether to enable this node. Nodes are enabled by default.
      '';
    };

    system = mkOption {
      type = types.nullOr (types.enum systems);
      default = null;
      example = "x86_64-linux";
      description = ''
        The target system architecture to compile for.
      '';
    };

    base = lib.mkOption {
      # In newer Nix versions, particularly with lazy trees, outPath of
      # flakes becomes a Nix-language path object. We deliberately allow this
      # to gracefully come through the interface in discussion with @roberth.
      #
      # See: https://github.com/NixOS/nixpkgs/pull/278522#discussion_r1460292639
      type = types.nullOr flakeRef;

      default = nodesConfig.base;
      defaultText = "nodes.base";

      example = lib.literalExpression "inputs.nixpkgs";

      description = ''
        The path to the nixpkgs source used to build a system. A `base` package set
        is required to be set, and can be specified via either:
        1. `options.nodes.base` (default `base` used for all systems)
        2. `options.nodes.nodes.<name>.base` (takes prescedence over `options.nodes.base`)

        This can also be optionally set if the NixOS system is not built with a flake but still uses
        pinned sources: set this to the store path for the nixpkgs sources used to build the system,
        as may be obtained by `fetchTarball`, for example.

        Note: the name of the store path must be "source" due to
        <https://github.com/NixOS/nix/issues/7075>.
      '';
    };

    homeManager = mkOption {
      type = types.nullOr flakeRef;
      default = nodesConfig.homeManager;
      defaultText = "nodes.homeManager";
      example = lib.literalExpression "inputs.home-manager";
      description = ''
        The path to the home-manager source. A `homeManager` flake reference
        is required to be set for `homes/` to be evaluated, and can be specified via either:
        1. `options.nodes.homeManager` (default `homManager` used for all systems)
        2. `options.nodes.nodes.<name>.homeManager` (takes prescedence over `options.nodes.homeManager`)
      '';
    };

    modules = mkOption {
      type = types.listOf types.raw;
      default = [];
      example = lib.literalExpression "[ { environment.systemPackages = [ pkgs.git ]; } ]";
      description = ''
        Shared modules to import; equivalent to the NixOS module system's `extraModules`.
      '';
    };

    args = mkOption {
      type = types.attrs;
      default = {};
      example = lib.literalExpression "{ inherit inputs; }";
      description = ''
        Shared args to provided for each node; equivalent to the NixOS module system's `specialArgs`.
      '';
    };

    groups = mkOption {
      # TODO: write a custom group type that validates better than types.attrs lol
      type = types.functionTo (types.listOf types.attrs);
      default = groups: [];
      example = lib.literalExpression "( groups: [ groups.servers groups.secure-boot ] )";
      description = ''
        A function from the `groups` hierarchy to a list of groups this node inherits from.
      '';

      apply = groupsFn:
        groupsFn nodesConfig.groups;
    };

    deploy = {
      user = mkOption {
        type = types.str;
        default = "root";
        example = "admin";
        description = ''
          The user that the system derivation will be built with. The command specified in
          `<node>.deploy.sudoCmd` will be used if `<node>.deploy.user` is not the
          same as `<node>.deploy.ssh.user` the same as above).
        '';
      };

      warnNonstandardDeployUser = mkOption {
        type = types.bool;
        default = true;
        example = false;
        description = ''
          Disables the warning that shows when `deploy.ssh.user` is set to a non-standard value.
        '';
      };

      # sudoCmd = mkOption {
      #   type = types.str;
      #   default = "sudo -u";
      #   example = "doas -u";
      #   description = ''
      #     Which sudo command to use. Must accept at least two arguments:
      #     1. the user name to execute commands as
      #     2. the rest is the command to execute
      #   '';
      # };

      interactiveSudo = mkOption {
        type = types.bool;
        default = false;
        example = false;
        description = ''
          Whether to enable interactive sudo (password based sudo).
          NOT RECOMMENDED. Use one of Snowflake's recommended auth methods instead.
        '';
      };

      remoteBuild = mkOption {
        type = types.bool;
        default = false;
        example = false;
        description = ''
          Whether to build the system derivation on the target system.
          Will also fetch all external dependencies from the target system's substituters.
        '';
      };

      rollback = mkOption {
        type = types.bool;
        default = true;
        example = true;
        description = ''
          Enables both `autoRollback` and `magicRollback`.
        '';
      };

      autoRollback = mkOption {
        type = types.bool;
        default = true;
        example = true;
        description = ''
          If the previous system derivation should be re-activated if activation fails.
        '';
      };

      magicRollback = mkOption {
        type = types.bool;
        default = true;
        example = true;
        description = ''
          TODO: im fucking lazy
        '';
      };

      activationTimeout = mkOption {
        type = types.int;
        default = 500;
        example = 30;
        description = ''
          Time window in seconds allowed for system derivation activation.
          If timeout occurs, remote deployment is considered to have failed.
        '';
      };

      confirmTimeout = mkOption {
        type = types.int;
        default = 30;
        example = 15;
        description = ''
          Time window in seconds allowed for activation confirmation.
          If timeout occurs, remote deployment is considered to have failed.
        '';
      };

      ssh = {
        host = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "dobutterfliescry.net";
          description = ''
            The host to connect to over ssh during deployment
          '';
        };

        user = mkOption {
          type = types.str;
          default = "snowbld";
          example = "custom-user";
          description = ''
            The user to connect to over ssh during deployment.
          '';
        };

        port = mkOption {
          type = types.int;
          default = 22;
          example = 2222;
          description = ''
            The port to connect to over ssh during deployment.
          '';
        };

        publicKeys = mkOption {
          type = types.listOf types.str;
          default = [];
          example = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIeyZuUUmyUYrYaEJwEMvcXqZFYm1NaZab8klOyK6Imr me@myputer"];
          description = ''
            SSH public keys that will be authorized to the deployment user.
            This key is intended solely for deployment, allowing for fine-grained permission control.
          '';
        };

        opts = mkOption {
          type = types.listOf types.str;
          default = [];
          example = ["-i" "~/.ssh/id_rsa"];
          description = ''
            Extra ssh arguments to use during deployment.
          '';
        };
      };
    };
  };

  config = let
    throwGotNull = name:
      throw ''
        [snow] `nodes.<name>.${name}` must be set for all nodes! (got: <null>)
      '';
    givenSystem =
      (config.system != null)
      || throwGotNull "system";

    givenBase =
      (config.base != null)
      || throwGotNull "base";

    givenHomeManager =
      (config.homeManager != null)
      || throwGotNull "homeManager";

    givenDeployHost =
      (config.deploy.ssh.host != null)
      || throwGotNull "deploy.ssh.host";
  in
    assert givenSystem
    && givenBase
    && givenHomeManager
    && givenDeployHost; {
      # extend these from the nodes configuration
      inherit (nodesConfig) modules args;
    };
}
