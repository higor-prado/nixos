# Remove User Import Special Case Progress

Related plan:
- [039-remove-user-import-special-case.md](../plans/039-remove-user-import-special-case.md)

## Baseline

- `modules/users/higorprado.nix` is already git-tracked.
- `flake.nix` still special-cases that file with an explicit import plus
  `import-tree.matchNot`.
- Active runtime consumers of `config.username` are narrow:
  - `modules/users/higorprado.nix`
  - `modules/hosts/predator.nix`
  - `modules/hosts/aurelius.nix`
  - `modules/features/core/nix-settings.nix`

## Phase 0 Hypothesis

- The explicit import/matchNot pair is likely leftover migration scaffolding.
- Since `modules/users/higorprado.nix` is tracked and now has a valid module
  shape, the honest next test is removing the carve-out entirely and letting
  `import-tree` import the whole tree uniformly.

## Execution

- Moved the `username` fact into `modules/users/higorprado.nix`, so the tracked
  user owner also owns the user identity fact it publishes.
- Removed `modules/meta.nix`.
- Restored `flake.nix` to the honest, uniform tree import:
  `inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules)`.
- Updated living docs and the option-boundary guardrail to reflect the new
  ownership.

## Validation

- `./scripts/run-validation-gates.sh structure`
- `nix flake metadata path:$PWD`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `./scripts/run-validation-gates.sh all`

All passed. The only remaining warnings were the already-known `xorg.libxcb`
deprecation warning and the desktop-matrix `system.stateVersion` warning.

## Residual Smells

- `scripts/check-option-declaration-boundary.sh` still names
  `modules/users/higorprado.nix` explicitly.
- `modules/features/desktop/niri.nix` and `modules/features/desktop/dms.nix`
  still capture `topConfig = config` only to read `username`.
