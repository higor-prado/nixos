# Multiple Hosts

## How hosts are declared

Each host is declared in `hardware/host-descriptors.nix` and has a corresponding
`modules/hosts/<name>.nix` file.

`hardware/host-descriptors.nix` lists script-only integration metadata
(`disko`, `homeManager`, etc.).

`modules/hosts/<name>.nix` is the den aspect that composes features and
declares the host system, hostname ownership, and imports hardware config.

`hardware/<name>/default.nix` owns the explicit runtime role signal
`custom.host.role` plus machine-specific hardware/default imports.

## Host roles

| Role | Purpose |
|------|---------|
| `desktop` | Full desktop with home-manager, Wayland compositor |
| `server` | Minimal headless, SSH only |

## Adding a new host

Use the skeleton script:

```bash
scripts/new-host-skeleton.sh <host-name> [desktop|server] [desktop-experience]
```

Then add the descriptor integrations to `hardware/host-descriptors.nix` and
adjust the generated `modules/hosts/<name>.nix` includes.

See [workflow: add a host](workflows/103-add-host.md).

## Current tracked hosts

- `predator` and `aurelius` are the only tracked live hosts.
- new host onboarding is handled by the generator and its fixture tests, not by
  keeping tracked example hosts in the live configuration surface.

## predator

Desktop workstation. Acer Predator laptop with NVIDIA RTX 4060 Max-Q.
Runs Niri compositor via DMS greeter. Full home-manager config.

## aurelius

Remote server. Minimal NixOS, SSH access, deployed from predator via `nh`.
