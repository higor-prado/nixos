# Multiple Hosts

## How hosts are declared

Each host is declared in `hardware/host-descriptors.nix` and has a corresponding
`modules/hosts/<name>.nix` file.

`hardware/host-descriptors.nix` lists script-only integration metadata
(`disko`, `homeManager`, etc.).

`modules/hosts/<name>.nix` declares one concrete dendritic
configuration that composes published feature modules and imports hardware
config.

## Adding a new host

Use the skeleton script:

```bash
scripts/new-host-skeleton.sh <host-name> [desktop|server] [desktop-experience]
```

Then add the descriptor integrations to `hardware/host-descriptors.nix` and
adjust the generated `modules/hosts/<name>.nix` imports.

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
