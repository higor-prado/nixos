# Hardware Boundary Fixes Progress

Related plan:
- [042-hardware-boundary-fixes.md](../plans/042-hardware-boundary-fixes.md)

## Baseline

- `hardware/predator/overlays.nix` still carries a `nixpkgs.overlays` package
  workaround for `dsearch`.
- `hardware/predator/default.nix` still imports `./overlays.nix`.
- `hardware/aurelius/default.nix` still sets `system.stateVersion`.
- `modules/features/core/system-base.nix` already materializes
  `system.stateVersion = "25.11"` universally.

## Execution

- Remove `hardware/predator/overlays.nix`.
- Move the `dsearch` workaround to the owner that actually needs it:
  `modules/features/desktop/dms.nix`.
- Remove `./overlays.nix` from `hardware/predator/default.nix`.
- Remove redundant `system.stateVersion` from `hardware/aurelius/default.nix`;
  `modules/features/core/system-base.nix` already provides `25.11`.
- Tighten living docs so `hardware/` is no longer described as a bucket for
  overlays.

## Validation

- `./scripts/run-validation-gates.sh structure`
- `nix flake metadata path:$PWD`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`
- `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.system.stateVersion`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `./scripts/run-validation-gates.sh all`
- `./scripts/check-docs-drift.sh`

All passed. The only remaining warnings were the already-known
`xorg.libxcb` deprecation warning and the desktop-matrix `system.stateVersion`
warning.
