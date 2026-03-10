# Core Options Refactor Progress

Date: 2026-03-09
Plan: `docs/for-agents/plans/004-core-options-refactor-plan.md`
Status: in progress

## Phase 0: Baseline and Guardrails

Status: complete

Baseline inventory:
- `core-options.nix` currently owns:
  - migration import wiring
  - `custom.user.name`
  - `custom.host.role`
  - `custom.ssh.settings`
  - `custom.fish.hostAbbreviationOverrides`
  - `custom.niri.standaloneSession`
  - validation-only `custom.<feature>.enable` flags
  - `options.host.*` declarations
- `config.host.*` still has live NixOS and Home Manager consumers
- host modules still hand-write `config.host.*` values

Planned baseline validation:
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/predator-core-options-before`
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/hm-core-options-before`
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-docs-drift.sh`

Result:
- baseline system closure: `/tmp/predator-core-options-before`
- baseline HM closure: `/tmp/hm-core-options-before`
- baseline structure gates and docs drift passed before refactor work

## Phase 1: Extract Migration Wiring

Status: complete

Goal:
- move alias/removed-option import wiring out of `core-options.nix`
- keep all option paths and migration behavior unchanged

Planned validation:
- `./scripts/check-option-migrations.sh`
- `./scripts/run-validation-gates.sh structure`
- `bash tests/scripts/new-host-skeleton-fixture-test.sh`
- `./scripts/check-docs-drift.sh`
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/predator-core-options-phase1`
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/hm-core-options-phase1`
- `nix store diff-closures /tmp/predator-core-options-before /tmp/predator-core-options-phase1`
- `nix store diff-closures /tmp/hm-core-options-before /tmp/hm-core-options-phase1`

Result:
- added `modules/features/option-migrations.nix` as the narrow migration-compatibility owner
- removed migration import wiring from `modules/features/core-options.nix`
- updated hosts, templates, fixtures, and onboarding docs to include `option-migrations` alongside `core-options`

Validation:
- `./scripts/check-option-migrations.sh` -> pass
- `bash tests/scripts/new-host-skeleton-fixture-test.sh` -> pass
- `./scripts/run-validation-gates.sh structure` -> pass
- `./scripts/check-docs-drift.sh` -> pass
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/predator-core-options-phase1` -> pass
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/hm-core-options-phase1` -> pass
- `nix store diff-closures /tmp/predator-core-options-before /tmp/predator-core-options-phase1` -> empty
- `nix store diff-closures /tmp/hm-core-options-before /tmp/hm-core-options-phase1` -> empty

## Phase 2: Derived Host-Context Bridge

Status: complete

Goal:
- derive `config.host.*` from den host metadata once
- stop hand-writing the NixOS mirror in every host module

Planned validation:
- `bash tests/scripts/new-host-skeleton-fixture-test.sh`
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-docs-drift.sh`
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/predator-core-options-phase2`
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/hm-core-options-phase2`
- `nix store diff-closures /tmp/predator-core-options-phase1 /tmp/predator-core-options-phase2`
- `nix store diff-closures /tmp/hm-core-options-phase1 /tmp/hm-core-options-phase2`

Result:
- added a temporary `host-context.nix` bridge as the derived `config.host.*` owner
- removed `options.host.*` declarations from `modules/features/core-options.nix`
- removed handwritten `config.host.*` assignments from tracked host modules and generated skeleton fixtures
- made `server-example` and `new-host` inherit `inputs`, `customPkgs`, and `llmAgentsPkgs` at the den host layer so the bridge has one authority

Notes:
- the first bridge attempt failed because a plain aspect attrset did not safely carry a host-parametric include
- the second attempt still duplicated definitions because it matched both `{ host }` and `{ host, user }` contexts
- final implementation uses an explicit `den.lib.parametric` aspect plus `den.lib.take.exactly` to bind only the host context once

Validation:
- `bash tests/scripts/new-host-skeleton-fixture-test.sh` -> pass
- `./scripts/run-validation-gates.sh structure` -> pass
- `./scripts/check-docs-drift.sh` -> pass
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/predator-core-options-phase2` -> pass
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/hm-core-options-phase2` -> pass
- `nix store diff-closures /tmp/predator-core-options-phase1 /tmp/predator-core-options-phase2` -> empty
- `nix store diff-closures /tmp/hm-core-options-phase1 /tmp/hm-core-options-phase2` -> empty

## Phase 3: Split User and Host Contract Options

Status: complete

Goal:
- move `custom.user.name` and `custom.host.role` out of `core-options.nix`
- keep option paths and behavior unchanged

Planned validation:
- `./scripts/check-config-contracts.sh`
- `./scripts/check-extension-contracts.sh`
- `bash tests/scripts/new-host-skeleton-fixture-test.sh`
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-docs-drift.sh`
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/predator-core-options-phase3`
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/hm-core-options-phase3`
- `nix store diff-closures /tmp/predator-core-options-phase2 /tmp/predator-core-options-phase3`
- `nix store diff-closures /tmp/hm-core-options-phase2 /tmp/hm-core-options-phase3`

Result:
- added `modules/features/user-context.nix` as the owner of `custom.user.name`
- added `modules/features/host-contracts.nix` as the owner of `custom.host.role`
- removed those declarations from `modules/features/core-options.nix`
- updated hosts, templates, fixtures, and onboarding docs to include the new contract aspects

Validation:
- `./scripts/check-extension-contracts.sh` -> pass
- `bash tests/scripts/new-host-skeleton-fixture-test.sh` -> pass
- `./scripts/run-validation-gates.sh structure` -> pass
- `./scripts/check-docs-drift.sh` -> pass
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/predator-core-options-phase3` -> pass
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/hm-core-options-phase3` -> pass
- `nix store diff-closures /tmp/predator-core-options-phase2 /tmp/predator-core-options-phase3` -> empty
- `nix store diff-closures /tmp/hm-core-options-phase2 /tmp/hm-core-options-phase3` -> empty

Known blocker not caused by this phase:
- `./scripts/check-config-contracts.sh` still fails on a preexisting tracked hardcoded-user rule:
  `found hardcoded home-manager user 'higorprado' in tracked CI/script/docs paths`

## Phase 4: Move Remaining Option Ownership Out of `core-options`

Status: complete

Goal:
- move real feature options to their feature owners
- move synthetic feature-presence flags to a dedicated validation-signal owner

Implementation note:
- the original plan said to move validation-only `custom.<feature>.enable` flags into the feature files
- that would make the options disappear on hosts that do not include the feature, breaking the current validation model
- this phase instead moves those declarations into a dedicated `feature-presence-signals` aspect so `core-options` can be emptied without regressing current checks

Planned validation:
- `./scripts/check-extension-contracts.sh`
- `bash tests/scripts/new-host-skeleton-fixture-test.sh`
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-docs-drift.sh`
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/predator-core-options-phase4`
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/hm-core-options-phase4`
- `nix store diff-closures /tmp/predator-core-options-phase3 /tmp/predator-core-options-phase4`
- `nix store diff-closures /tmp/hm-core-options-phase3 /tmp/hm-core-options-phase4`

Result:
- moved `custom.ssh.settings` declaration into `modules/features/ssh.nix`
- moved `custom.fish.hostAbbreviationOverrides` declaration into `modules/features/fish.nix`
- moved `custom.niri.standaloneSession` declaration into `modules/features/niri.nix`
- moved validation-only `custom.<feature>.enable` declarations into `modules/features/feature-presence-signals.nix`
- `core-options.nix` is now behavior-empty

Notes:
- the first phase-4 build failed because adding `options` to `ssh.nix` and `niri.nix` required their live settings to move under `config`
- after that structural fix, the outputs matched the phase-3 baseline

Validation:
- `./scripts/check-extension-contracts.sh` -> pass
- `bash tests/scripts/new-host-skeleton-fixture-test.sh` -> pass
- `./scripts/run-validation-gates.sh structure` -> pass
- `./scripts/check-docs-drift.sh` -> pass
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/predator-core-options-phase4` -> pass
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/hm-core-options-phase4` -> pass
- `nix store diff-closures /tmp/predator-core-options-phase3 /tmp/predator-core-options-phase4` -> empty
- `nix store diff-closures /tmp/hm-core-options-phase3 /tmp/hm-core-options-phase4` -> empty

## Phase 5: Retire `core-options`

Status: completed

Goal:
- delete the now-empty `core-options.nix` shim
- stop teaching `core-options` as the central option registry

Result:
- deleted the empty `modules/features/core-options.nix` shim
- removed `core-options` from live host includes, templates, and skeleton fixtures
- updated ownership and onboarding docs so they no longer teach `core-options` as the central option registry

Validation:
- `bash tests/scripts/new-host-skeleton-fixture-test.sh`
- `bash tests/scripts/new-host-skeleton-fixture-test.sh` -> pass
- `./scripts/run-validation-gates.sh structure` -> pass
- `./scripts/check-docs-drift.sh` -> pass
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/predator-core-options-phase5` -> pass
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/hm-core-options-phase5` -> pass
- `nix store diff-closures /tmp/predator-core-options-phase4 /tmp/predator-core-options-phase5` -> empty
- `nix store diff-closures /tmp/hm-core-options-phase4 /tmp/hm-core-options-phase5` -> empty

Notes:
- repo-wide search confirms `core-options` now remains only in historical/current diagnostic docs and refactor plan records, not in live host wiring

## Closeout Verification

Status: completed

Purpose:
- confirm the final doc/template cleanup still satisfies the broader non-Nix regression checks from the plan

Validation:
- `bash scripts/check-changed-files-quality.sh` -> pass
- `bash tests/scripts/gate-cli-contracts-test.sh` -> pass
- `bash tests/scripts/run-validation-gates-fixture-test.sh` -> pass
- `bash tests/scripts/new-host-skeleton-fixture-test.sh` -> pass
