# nix-mcp-gateway

Local deployment tooling for [agentic-community/mcp-gateway-registry](https://github.com/agentic-community/mcp-gateway-registry)
on macOS, packaged as a nix-darwin module (and standalone CLI via `nix run`).

Deploys upstream's blessed path — `build_and_run.sh --prebuilt` (docker
compose, multi-arch images from `public.ecr.aws`) — inside a Colima VM, and
wraps the full lifecycle with `mcpgw-*` commands:

| Command | Purpose |
|---|---|
| `mcpgw-install` | clone/update the repo, seed `.env` with generated secrets, download the embedding model |
| `mcpgw-up` | start Colima + the 8-container prebuilt stack |
| `mcpgw-bootstrap` | one-time Keycloak realm/client/user initialization |
| `mcpgw-down` / `mcpgw-status` / `mcpgw-delete` | lifecycle |
| `mcpgw-help` | quickstart |

## Use from nix-darwin

```nix
{
  inputs.nix-mcp-gateway.url = "github:jsandov/nix-mcp-gateway";
  inputs.nix-mcp-gateway.inputs.nixpkgs.follows = "nixpkgs";

  # in your darwin configuration:
  imports = [ inputs.nix-mcp-gateway.darwinModules.default ];
  services.mcp-gateway.enable = true;
}
```

Options: `workDir`, `repoUrl`, `repoRef`, `vmCpus`, `vmMemoryGiB`, `vmDiskGiB`
(see `modules/darwin.nix`).

## Use from the CLI

```sh
nix run github:jsandov/nix-mcp-gateway#mcpgw-install
nix run github:jsandov/nix-mcp-gateway#mcpgw-up
```

## Upstream quirks handled

- Host-side `prepare-log-dirs.sh` sudo prompt neutralized; the log dir is
  prepared inside the VM instead (passwordless sudo via `colima ssh`).
- `keycloak/{themes,providers}` bind-mount sources created (missing on a
  fresh upstream clone; the VM daemon can't create them through the mount).
- The trailing interactive "follow the logs?" prompt in `build_and_run.sh`
  is answered automatically so exit codes stay meaningful.

**Caution:** recreating the Colima VM (`colima delete`) wipes docker volumes
(Keycloak realm, MongoDB) — re-run `mcpgw-bootstrap` afterwards.

Load testing lives in the companion flake:
[nix-mcp-gateway-k6](https://github.com/jsandov/nix-mcp-gateway-k6).
