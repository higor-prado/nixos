# Design Philosophy

## One source of truth

Every piece of configuration lives in exactly one place. No duplicates,
no shadow configs, no "also configure this in another file."

## Feature aspects, not monolithic files

Each feature (`fish`, `niri`, `editor-neovim`) is an independent den aspect.
Features compose by listing them in a host's `includes` list. Adding a feature
to a host is one line.

## Den-native

This repo uses [den](https://github.com/vic/den) to structure NixOS
modules. Den handles:
- Auto-discovery of modules under `modules/**/*.nix`
- Aspect composition via `includes`
- Host declaration via `den.hosts`

## Separation of concerns

| Layer | Responsibility |
|-------|---------------|
| `modules/features/` | What the system can do |
| `modules/desktops/` | Desktop compositions (which features together) |
| `modules/hosts/` | Which features each host has |
| `hardware/<name>/` | Hardware, disks, boot — machine-specific only |
| `private/` | Private overrides (gitignored) |

## Private config, never in git

Real usernames, SSH keys, and personal paths live in gitignored private override
files. The tracked `*.nix.example` files show the expected shape without
carrying real private data. This personal repo tracks the canonical
`higorprado` user aspect by default and keeps real private overrides out of git.
