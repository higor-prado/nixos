# Remove User Import Special Case

## Goal

Remove the explicit import of `modules/users/higorprado.nix` and the matching
`import-tree.matchNot` carve-out from `flake.nix`, restoring a single honest
auto-import path for every tracked module under `modules/`.

## Problem

The current shape in `flake.nix` is wrong:

```nix
imports = [
  ./modules/users/higorprado.nix
  (inputs.import-tree.matchNot ".*/modules/users/higorprado\\.nix$" ./modules)
];
```

That means the repo no longer has one uniform import mechanism. A single file
gets special treatment because `username` is currently modeled in a way that
forces deterministic import ordering.

This is exactly the kind of local exception that should not survive in a
dendritic-first repo.

## Scope

In scope:
- `flake.nix`
- `modules/users/higorprado.nix`
- any direct consumers of `config.username`
- option-boundary policy/docs that currently justify the special-case

Out of scope:
- changing feature behavior
- adding new runtime carriers
- `flake.lock`

## Current State

- `modules/users/higorprado.nix` declares `options.username`
- hosts and some lower-level modules read `config.username`
- `flake.nix` explicitly imports `higorprado.nix` and excludes it from
  recursive import-tree loading to keep that fact deterministic

## Desired End State

- `flake.nix` imports `./modules` through one mechanism only
- no `matchNot` carve-out for a specific user file
- no explicit import of a single tracked module just to force ordering
- the tracked user model remains explicit and readable

## Decision Criteria

Any acceptable solution must satisfy all of these:

1. No file-specific import special-case in `flake.nix`
2. No replacement carrier/inventory/contract abstraction
3. No fake “meta” file reintroduced just to move the same problem elsewhere
4. Real runtime/build parity preserved

## Phases

### Phase 0: Prove Why The Special-Case Exists

Targets:
- `flake.nix`
- `modules/users/higorprado.nix`
- all active `config.username` consumers

Changes:
- none
- map exactly which modules need `config.username`
- classify each use as:
  - truly needs a repo-wide fact
  - can read existing lower-level state instead
  - should be made explicit in the host/user owner instead

Validation:
- `rg -n "config\\.username" modules docs scripts tests`
- `sed -n '1,220p' flake.nix`
- `sed -n '1,220p' modules/users/higorprado.nix`

### Phase 1: Choose The Honest Shape

Targets:
- user identity modeling
- host/user consumers

Changes:
- choose one of these only if it removes the special-case cleanly:
  - eliminate `username` entirely and make the user owner/file name the source
    of truth
  - keep `username`, but move its ownership to a module that does not require
    a file-specific import carve-out

Non-goals:
- no second special-case
- no new helper layer

Validation:
- explain why the chosen shape removes the import-order problem instead of
  shifting it

### Phase 2: Apply Minimal Refactor

Targets:
- `flake.nix`
- affected modules/docs/gates only

Changes:
- remove explicit user import
- remove `matchNot` special-case
- update only the minimal set of consumers/boundary docs

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix flake metadata path:$PWD`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.stateVersion`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.stateVersion`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

### Phase 3: Final Sanity Sweep

Targets:
- `flake.nix`
- living docs

Changes:
- confirm no file-specific import carve-outs remain
- confirm no new artificial surface was introduced

Validation:
- `rg -n "matchNot|modules/users/higorprado\\.nix" flake.nix docs scripts`
- `./scripts/check-docs-drift.sh`

## Definition of Done

- `flake.nix` no longer special-cases `modules/users/higorprado.nix`
- all tracked modules under `modules/` enter through one coherent import path
- runtime stays green
- no replacement abstraction is added just to make the code “work”
