# Remove Bidirectional Progress

## Status

Completed

## Related Plan

- [002-remove-bidirectional-plan.md](/home/higorprado/nixos/docs/for-agents/archive/plans/002-remove-bidirectional-plan.md)

## Baseline

- The worktree `flake.lock` had already moved `den` past the bidirectional removal, so the tracked repo no longer evaluated with `den._.bidirectional` present upstream.
- A temporary copy with only `den._.bidirectional` removed still built, but its Home Manager surface collapsed hard:
  - `builtins.length home.packages = 10`
  - `programs.git.enable = false`
  - `programs.starship.enable = false`
- The practical regression was not "cannot build"; it was "host-owned Home Manager config no longer reaches users unless it is routed explicitly through the host mutual surface".

## Slices

### Slice 1

- created the active plan and progress surfaces for the migration work

Validation:
- `./scripts/check-docs-drift.sh`

Diff result:
- planning/progress docs only

Commit:
- pending

### Slice 2

- Confirmed from upstream `den` code/tests that `mutual-provider` now reads host-to-user config from `host._.to-users`.
- Inventoried the host-owned Home Manager surfaces included by `predator` and `aurelius`.
- Verified that scattering `provides.to-users` across reusable aspects was insufficient because those contributions are not discovered automatically through host includes.

Validation:
- `nix build --no-link path:/tmp/nixos-bidir-test#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:/tmp/nixos-bidir-test#nixosConfigurations.predator.config.system.build.toplevel`
- `nix eval --impure --raw --expr 'let flake = builtins.getFlake "path:/tmp/nixos-bidir-test"; cfg = flake.nixosConfigurations.predator.config.home-manager.users.higorprado; in toString (builtins.length cfg.home.packages)'`
- `nix eval --impure --raw --expr 'let flake = builtins.getFlake "path:/tmp/nixos-bidir-test"; cfg = flake.nixosConfigurations.predator.config.home-manager.users.higorprado; in if cfg.programs.git.enable then "true" else "false"'`
- `nix eval --impure --raw --expr 'let flake = builtins.getFlake "path:/tmp/nixos-bidir-test"; cfg = flake.nixosConfigurations.predator.config.home-manager.users.higorprado; in if cfg.programs.starship.enable then "true" else "false"'`

Diff result:
- no tracked repo changes; temporary-copy baseline and migration direction confirmed

Commit:
- pending

### Slice 3

- Removed `den._.bidirectional` from [modules/users/higorprado.nix](/home/higorprado/nixos/modules/users/higorprado.nix).
- Converted host-owned Home Manager surfaces in reusable desktop/dev/shell/system aspects to explicit host-to-user helper projections under `_.to-users`.
- Added host-level `_.to-users.includes` aggregators in [modules/hosts/predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix) and [modules/hosts/aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix).
- Added the same aggregation pattern to the composite [modules/features/desktop/theme.nix](/home/higorprado/nixos/modules/features/desktop/theme.nix) aspect so its child theme projections still reach users.

Validation:
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`
- `nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.predator.config.home-manager.users.higorprado; in toString (builtins.length cfg.home.packages)'`
- `nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.predator.config.home-manager.users.higorprado; in if cfg.programs.git.enable then "true" else "false"'`
- `nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.predator.config.home-manager.users.higorprado; in if cfg.programs.starship.enable then "true" else "false"'`

Diff result:
- `predator` Home Manager surface recovered to `141` packages
- `programs.git.enable` and `programs.starship.enable` returned to `true`
- bidirectional dependency removed from tracked code

Commit:
- pending

### Slice 4

- Ran full repo validation after the routing migration.

Validation:
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `./scripts/check-docs-drift.sh`
- `./scripts/check-repo-public-safety.sh`
- `./scripts/run-validation-gates.sh all`

Diff result:
- migration validated successfully
- existing warnings remained:
  - `xorg.libxcb` deprecation warning
  - `system.stateVersion is not set` on desktop matrix validation paths

Commit:
- pending

## Final State

- `den._.bidirectional` is gone from the tracked repo.
- Host-owned Home Manager config now reaches users through explicit `_.to-users` projections aggregated at the host aspect level.
- The no-bidirectional regression baseline (`10` Home packages, `git=false`, `starship=false`) was eliminated; `predator` now evaluates with `141` Home packages and the expected major programs enabled.
- Validation, docs drift, and public-safety checks all passed after the migration.
