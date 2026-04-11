# Spicetify Integration Progress

## Status

In progress

## Related Plan

- [076-spicetify-integration.md](/home/higorprado/nixos/docs/for-agents/plans/076-spicetify-integration.md)

## Baseline

- There were no tracked `spicetify` or `spotify` references in the repo before
  this work.
- The current music owner is
  [music-client.nix](/home/higorprado/nixos/modules/features/desktop/music-client.nix).
- The current desktop Catppuccin facts are still centralized in
  [theme-base.nix](/home/higorprado/nixos/modules/features/desktop/theme-base.nix).
- `flake.lock` already had user changes before this slice and remains a shared
  edit surface.

## Slices

### Slice 1

- added `spicetify-nix` to
  [flake.nix](/home/higorprado/nixos/flake.nix)
- integrated Spicetify into
  [music-client.nix](/home/higorprado/nixos/modules/features/desktop/music-client.nix)
- owner choice:
  - kept Spotify/Spicetify inside the existing Home Manager music owner
  - imported `inputs.spicetify-nix.homeManagerModules.spicetify` there
- theme choice:
  - reused `config.catppuccin.flavor` instead of duplicating `mocha`
- configured requested extensions:
  - `adblockify`
  - `hidePodcasts`
  - `shuffle`
- validation:
  - `nix flake lock --update-input spicetify-nix` -> ok
  - `./scripts/check-docs-drift.sh` -> ok
  - `nix flake metadata` -> ok
  - `./scripts/run-validation-gates.sh structure` -> ok
  - `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.programs.spicetify.enable` -> `true`
  - `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.programs.spicetify.colorScheme` -> `"mocha"`
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path` -> ok
  - `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel` -> ok
- diff result:
  - the HM and system closures now include `spotify`, `spicetify-cli`, and the
    Catppuccin Spicetify theme
  - the Spicetify color scheme is wired to the same Catppuccin flavor already
    exposed in the desktop theme layer
- commit:
  - pending

## Final State

- Open. Declarative Spicetify integration is implemented and builds cleanly.
- The next proof step is live activation/runtime verification on `predator`.
