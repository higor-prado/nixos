# Predator User Routing Cleanup

## Goal

Remove the tracked `if host.name == "predator"` workaround from the `higorprado` user aspect and replace it with a den-native explicit host/user routing pattern that matches current `den` philosophy.

## Scope

In scope:
- replace the `predator`-specific user-group wiring with an explicit den routing pattern
- keep the resulting behavior identical for evaluated `predator` groups
- update any living docs touched by the cleanup if the final pattern changes repo guidance

Out of scope:
- unrelated `flake.lock` changes
- broad den-style cleanup across unrelated modules
- archive-only doc rewrites

## Current State

- [modules/users/higorprado.nix](/home/higorprado/nixos/modules/users/higorprado.nix) currently contains a parametric include with `if host.name == "predator"`.
- That shape now works, but it is an ugly host-name conditional inside a user aspect.
- Current local `den` guidance favors explicit host/user pair routing for host-specific user contributions:
  - `provides.<host>` patterns in `/home/higorprado/git/den/templates/example/modules/aspects/alice.nix`
  - `den._.mutual-provider` in `/home/higorprado/git/den/modules/aspects/provides/mutual-provider.nix`
- The evaluated `predator` target state to preserve is:
  - `["video","audio","input","docker","rfkill","uinput","linuwu_sense","wheel","networkmanager"]`

## Desired End State

- No tracked `if host.name == "predator"` workaround remains in the repo.
- `predator`-specific user-group wiring is expressed through an explicit den-native host/user routing pattern.
- The resulting shape is easy to read and clearly communicates ownership.
- `predator` still evaluates and builds with the same intended user-group result.

## Phases

### Phase 0: Baseline

Validation:
- confirm the current workaround location
- confirm the current evaluated `predator` group list
- identify the minimal den-native routing mechanism to adopt

### Phase 1: Replace Host-Name Conditional With Explicit Routing

Targets:
- [modules/users/higorprado.nix](/home/higorprado/nixos/modules/users/higorprado.nix)
- [modules/hosts/predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
- possibly one repo-level den/default wiring location if `den._.mutual-provider` needs to be enabled centrally

Changes:
- remove the inline `if host.name == "predator"` conditional from the user aspect
- express the `predator`-only contribution through explicit den routing, most likely `provides.predator`
- add only the minimal required supporting wiring for that route

Validation:
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.users.users.higorprado.extraGroups`
- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`

Diff expectation:
- the ugly host-name conditional is gone
- `predator` retains the same evaluated group membership

Commit target:
- `refactor(predator): route user groups through explicit den pairing`

### Phase 2: Validate Broader Impact

Targets:
- touched repo files only

Changes:
- no further functional changes unless validation exposes a follow-up issue

Validation:
- `./scripts/check-repo-public-safety.sh`
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh`

Diff expectation:
- only the intended routing cleanup remains

Commit target:
- none if Phase 1 is sufficient

## Risks

- enabling `den._.mutual-provider` in the wrong scope could widen behavior beyond the intended `predator`/`higorprado` pair
- the cleanest den-native route may require a small amount of additional wiring that should stay readable
- preserving exact group ordering may require checking merge behavior explicitly

## Definition of Done

- the repo contains no `if host.name == "predator"` workaround for this case
- the `predator`-specific user-group wiring is expressed through an explicit den-native route
- `predator` still evaluates with the intended group set
- validation gates and safety/doc checks pass after the refactor
