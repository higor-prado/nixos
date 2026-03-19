# Den Mutual Routing Doc Alignment Progress

## Status

Completed

## Related Plan

- [003-den-mutual-routing-doc-alignment.md](/home/higorprado/nixos/docs/for-agents/archive/plans/003-den-mutual-routing-doc-alignment.md)

## Baseline

- The repo already works without `den._.bidirectional`.
- Durable docs still describe the old den-native Home Manager assumption for
  host-owned features.
- The pinned repo input is `den` `5ab19d88134bfb623e6068987cd79605c7da0d41`,
  which is newer than the local checkout in `~/git/den`.
- This task validated the architecture against the pinned `den` sources before
  changing code style or docs.

## Slices

### Slice 1

- created the active plan and progress log for the doc-alignment pass

Validation:
- scaffold only

Diff result:
- planning docs only

Commit:
- pending

### Slice 2

- Audited the pinned `den` source from the nix store instead of trusting the
  local clone.
- Confirmed from upstream code and tests that:
  - current `den` is unidirectional by default
  - host-owned top-level `.homeManager` does not reach users automatically
  - `den._.mutual-provider` consumes `den.aspects.<host>._.to-users` and
    `den.aspects.<user>._.to-hosts`
  - the public authoring API remains `provides.to-users` / `provides.to-hosts`

Validation:
- `nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); in flake.inputs.den.outPath'`
- `nix eval --json --impure --expr 'let flake = builtins.getFlake (toString ./.); in { denRev = flake.inputs.den.rev or null; denOutPath = flake.inputs.den.outPath; }'`
- source review under `/nix/store/wihwz3jydh7rzd3gqr4p4nmqhm40n1ab-source`

Diff result:
- no tracked code changes yet
- final routing rationale confirmed against pinned upstream sources

Commit:
- pending

### Slice 3

- Tightened the tracked repo to use the public `den` API in definitions:
  - feature/desktop aspects now declare host-to-user HM with
    `provides.to-users`
  - host/composition aggregation remains on `._.to-users`, matching what
    `den._.mutual-provider` resolves internally
- Revalidated that the post-migration HM surface remained intact.

Validation:
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`
- `nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.predator.config.home-manager.users.higorprado; in toString (builtins.length cfg.home.packages)'`
- `nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.predator.config.home-manager.users.higorprado; in if cfg.programs.git.enable then "true" else "false"'`
- `nix eval --impure --raw --expr 'let flake = builtins.getFlake (toString ./.); cfg = flake.nixosConfigurations.predator.config.home-manager.users.higorprado; in if cfg.programs.starship.enable then "true" else "false"'`

Diff result:
- public API and internal consumption paths are now deliberately separated
- `predator` still evaluates with `141` Home packages, `git = true`, and `starship = true`

Commit:
- pending

### Slice 4

- Updated durable agent docs to teach the current mutual-routing model.
- Removed obsolete live-doc references to `bidirectional`.

Validation:
- `rg -n 'bidirectional' docs/for-agents/000-operating-rules.md docs/for-agents/001-repo-map.md docs/for-agents/002-den-architecture.md docs/for-agents/003-module-ownership.md docs/for-agents/006-extensibility.md docs/for-agents/007-option-migrations.md docs/for-agents/999-lessons-learned.md`
- `./scripts/check-docs-drift.sh`
- `./scripts/check-repo-public-safety.sh`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `./scripts/run-validation-gates.sh all`

Diff result:
- live docs now distinguish user-owned `.homeManager` from host-owned mutual routing
- validation stayed green after the doc and API-alignment pass
- existing warnings remained:
  - `xorg.libxcb` deprecation warning
  - `system.stateVersion is not set` on desktop matrix validation paths

Commit:
- pending

## Final State

- The repo still works without `den._.bidirectional`.
- The code now uses the public `den` mutual-routing API (`provides.to-users`)
  in aspect definitions and the internal `._.to-users` namespace only where the
  host aggregation and upstream battery actually consume it.
- Durable docs now reflect the current `den` philosophy instead of the removed
  bidirectional model.
