# Post-Dendritic Audit Cleanups Progress

Related plan:
- [043-post-dendritic-audit-cleanups.md](../plans/043-post-dendritic-audit-cleanups.md)

## Baseline

- `scripts/check-option-declaration-boundary.sh` still allows
  `modules/users/higorprado.nix` by exact path.
- `modules/features/desktop/niri.nix` and `modules/features/desktop/dms.nix`
  still capture `topConfig = config` only to read `username`.
- `scripts/check-desktop-composition-matrix.sh` still hardcodes `"higorprado"`
  in the synthetic system config.
- `scripts/check-extension-contracts.sh` still checks dead legacy paths under
  `modules/options/` and `modules/profiles/`.

## Execution

- `check-option-declaration-boundary.sh` now allows the tracked user owner
  category via `modules/users/`, not one literal file path.
- `modules/features/desktop/niri.nix` now captures `userName = config.username`
  directly instead of `topConfig = config`.
- `modules/features/desktop/dms.nix` now does the same.
- `check-desktop-composition-matrix.sh` now uses a single local `username`
  binding in the synthetic config instead of repeating the real username inline.
- `check-extension-contracts.sh` dropped checks for dead historical paths under
  `modules/options/`.
- `modules/users/higorprado.nix` was intentionally left unchanged because no
  simplification with clear net benefit emerged from the audit.

## Validation

- `./scripts/run-validation-gates.sh structure`
- `bash tests/scripts/run-validation-gates-fixture-test.sh`
- `./scripts/check-desktop-composition-matrix.sh`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `./scripts/run-validation-gates.sh all`

All passed. Remaining warnings were the already-known `xorg.libxcb`
deprecation warning and the desktop-matrix `system.stateVersion` warning.
