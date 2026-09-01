{ config, lib, pkgs, ... }:

let
  cfg = config.services.mcp-gateway;

  scripts = import ./scripts.nix {
    inherit pkgs;
    workDirDefault = cfg.workDir;
    inherit (cfg) repoUrl repoRef vmCpus vmMemoryGiB vmDiskGiB;
  };
in
{
  options.services.mcp-gateway = {
    enable = lib.mkEnableOption "MCP Gateway Registry local deployment tooling (mcpgw-* scripts)";

    workDir = lib.mkOption {
      type = lib.types.str;
      default = "$HOME/mcp-gateway-registry";
      description = ''
        Writable working clone of the upstream repo. Shell-expanded at
        runtime ($HOME is fine); override per-invocation with MCPGW_WORKDIR.
      '';
    };

    repoUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://github.com/agentic-community/mcp-gateway-registry";
      description = "Upstream repository URL.";
    };

    repoRef = lib.mkOption {
      type = lib.types.str;
      default = "main";
      description = ''
        Git ref to check out (branch or tag — e.g. "1.29.0" to pin a
        release). Prebuilt images track :latest by default; pin
        REGISTRY_VERSION/AUTH_SERVER_VERSION/MCPGW_VERSION in .env to match.
      '';
    };

    vmCpus = lib.mkOption {
      type = lib.types.int;
      default = 4;
      description = "Colima VM CPUs (applied on first VM creation only).";
    };

    vmMemoryGiB = lib.mkOption {
      type = lib.types.int;
      default = 8;
      description = "Colima VM memory in GiB (upstream-documented minimum).";
    };

    vmDiskGiB = lib.mkOption {
      type = lib.types.int;
      default = 60;
      description = "Colima VM disk in GiB.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = builtins.attrValues scripts;
  };
}
