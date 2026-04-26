# Start Here

This repo is a NixOS configuration for personal machines managed with a
top-level dendritic pattern. It configures:

- **predator** — Acer Predator desktop workstation (Wayland/Hyprland desktop)
- **aurelius** — remote server (minimal, SSH-accessible)
- **cerebelo** — Orange Pi 5 (RK3588S) headless server

## How to build and switch

```bash
# Build and switch (local)
nh os switch path:$HOME/nixos

# Build and switch (aurelius, from predator)
nh os switch path:$HOME/nixos#aurelius \
  --target-host aurelius --build-host aurelius \
  -e passwordless
```

## Key abbreviations (fish shell)

| Abbr | Action |
|------|--------|
| `npu` | Update flake lockfile |
| `npub` | Update + build |
| `npus` | Update + switch |
| `nau` | Update flake (aurelius) |
| `naus` | Update + switch aurelius |

## Adding a package

Features live under `modules/features/<category>/` as top-level dendritic
modules that publish lower-level NixOS and/or Home Manager modules. See
[workflow: add a feature](workflows/102-add-feature.md).

## Private config

Personal settings (real username, SSH keys, theme paths) live in untracked
private.nix files. See [for-humans/04-private-overrides.md](04-private-overrides.md).
