# Fish And Zen Cleanup Progress

## Status

Completed.

## Completed Work

- simplified `modules/features/shell/fish.nix` without changing ownership
- extracted the inline Zen theme sync shell body from
  `modules/features/desktop/theme-zen.nix` into tracked
  `config/apps/zen/sync-catppuccin-theme.sh`
- updated structure docs to reflect `config/apps/zen/`

## Validation Run

- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh structure`
- `bash scripts/check-changed-files-quality.sh`
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel`
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix store diff-closures` for before/after system and HM outputs

## Results

- fish cleanup:
  - predator system diff: empty
  - predator HM diff: empty
- zen extraction:
  - predator HM diff: empty
  - predator system diff: `sync-zen-catppuccin: ∅ -> ε`, expected because the
    extracted tracked script now produces its own derivation in the closure

## Notes

- The first Zen extraction attempt failed because the new tracked script was
  still untracked; Nix flakes do not include untracked files in the source.
- Staging `config/apps/zen/sync-catppuccin-theme.sh` fixed that without changing
  behavior.
