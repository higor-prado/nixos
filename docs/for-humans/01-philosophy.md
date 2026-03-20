# Design Philosophy

## One source of truth

Every piece of configuration lives in exactly one place. No duplicates,
no shadow configs, no "also configure this in another file."

## Dendritic feature modules, not monolithic files

Each feature (`fish`, `niri`, `editor-neovim`) is an independent top-level
module that publishes lower-level NixOS and/or Home Manager modules.
Hosts compose by importing those published modules explicitly.

## Dendritic first

This repo uses the dendritic pattern: every non-entry-point Nix file is a
top-level module, and concrete NixOS/Home Manager configs are declared from the
top level.

## Separation of concerns

| Layer | Responsibility |
|-------|---------------|
| `modules/features/` | Feature-owned lower-level modules |
| `modules/desktops/` | Desktop composition lower-level modules |
| `modules/hosts/` | Host inventory + concrete configuration declarations |
| `hardware/<name>/` | Hardware, disks, boot — machine-specific only |
| `private/` | Private overrides (gitignored) |

## Private config, never in git

Real usernames, SSH keys, and personal paths live in gitignored private override
files. The tracked `*.nix.example` files show the expected shape without
carrying real private data. This personal repo tracks the canonical
`higorprado` user aspect by default and keeps real private overrides out of git.
