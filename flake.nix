{
  description = "Local deployment tooling for agentic-community/mcp-gateway-registry on macOS (Colima + docker compose), as a nix-darwin module and CLI";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";

  outputs = { self, nixpkgs }:
    let
      # Colima/Lima run on macOS; keep the CLI surface scoped to darwin.
      systems = [ "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: import nixpkgs { inherit system; };

      scriptsFor = system: import ./modules/scripts.nix { pkgs = pkgsFor system; };

      toolset = system:
        (pkgsFor system).buildEnv {
          name = "mcp-gateway-toolset";
          paths = builtins.attrValues (scriptsFor system);
        };
    in
    {
      # ---------- Module (nix-darwin consumers) ----------
      darwinModules.default = import ./modules/darwin.nix;

      # ---------- Library export ----------
      lib.scripts = args: import ./modules/scripts.nix args;

      # ---------- CLI surface ----------
      # `nix shell github:jsandov/nix-mcp-gateway` → mcpgw-* on PATH
      packages = forAllSystems (system: {
        default = toolset system;
        mcp-gateway-toolset = toolset system;
      });

      # `nix run github:jsandov/nix-mcp-gateway#mcpgw-up` (etc.)
      apps = forAllSystems (system:
        let
          scripts = scriptsFor system;
          mkApp = name: { type = "app"; program = "${scripts.${name}}/bin/${name}"; };
        in {
          mcpgw-install = mkApp "mcpgw-install";
          mcpgw-up = mkApp "mcpgw-up";
          mcpgw-bootstrap = mkApp "mcpgw-bootstrap";
          mcpgw-down = mkApp "mcpgw-down";
          mcpgw-status = mkApp "mcpgw-status";
          mcpgw-delete = mkApp "mcpgw-delete";
          mcpgw-help = mkApp "mcpgw-help";
          default = mkApp "mcpgw-help";
        });
    };
}
