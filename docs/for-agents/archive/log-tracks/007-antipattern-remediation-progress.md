# Antipattern Remediation Progress

Date: 2026-03-09
Status: in progress

Plan:
- `docs/for-agents/plans/005-antipattern-remediation-plan.md`

Source diagnosis:
- `docs/for-agents/current/003-antipattern-diag.md`

## Scope

This log tracks execution of the antipattern-remediation plan after the
`core-options` refactor.

Tracked phases:
1. baseline and authority capture
2. shared/runtime boundary cleanup
3. synthetic feature-signal removal
4. shell ownership unification
5. host metadata deduplication
6. den-native user ownership migration
7. host-context bridge removal
8. desktop/home-path cleanup and final docs

## Baseline

Status: completed

Recorded before Phase 1:
- system closure baseline: `/tmp/antipattern-before-system`
- HM closure baseline: `/tmp/antipattern-before-hm`
- system path:
  - `/nix/store/lzqjnlzscqvmn33kgx0b8za6wyxmbv02-nixos-system-predator-26.05.20260308.9dcb002`
- HM path:
  - `/nix/store/hfx0438y7k2rpq403v6qgnwrd6qvr058-home-manager-path`
- authority snapshots:
  - `predator.config.custom.user.name = higorprado`
  - `aurelius.config.custom.user.name = ops`
  - `predator.config.custom.host.role = desktop`
  - `aurelius.config.custom.host.role = server`

Validation:
- `./scripts/run-validation-gates.sh structure` -> pass
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/antipattern-before-system` -> pass
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/antipattern-before-hm` -> pass
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.custom.user.name` -> `higorprado`
- `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.custom.user.name` -> `ops`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.custom.host.role` -> `desktop`
- `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.custom.host.role` -> `server`

## Phase Checklist

### Phase 0: Baseline and Authority Capture

Status: completed

### Phase 1: Remove Shared/Runtime Boundary Ambiguity

Status: completed

Result:
- removed `runtime-smoke` as a stage of `scripts/run-validation-gates.sh`
- reclassified `scripts/check-runtime-smoke.sh` from `gate-check` to `shared-aux`
- updated the validation registry, test-pyramid metadata, fixture tests, and validation docs to match the new boundary

Validation:
- `./scripts/run-validation-gates.sh structure` -> pass
- `bash tests/scripts/run-validation-gates-fixture-test.sh` -> pass
- `bash scripts/check-changed-files-quality.sh` -> pass
- `./scripts/check-docs-drift.sh` -> pass
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/antipattern-phase1-system` -> pass
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/antipattern-phase1-hm` -> pass
- `nix store diff-closures /tmp/antipattern-before-system /tmp/antipattern-phase1-system` -> empty
- `nix store diff-closures /tmp/antipattern-before-hm /tmp/antipattern-phase1-hm` -> empty

Notes:
- the runtime smoke helper remains tracked and documented as predator-scoped local tooling
- the canonical shared validation surface is now limited to `structure`, declared host stages, and `all`

### Phase 2: Remove Synthetic Feature-Presence Signals

Status: completed

Result:
- replaced validation reads of `custom.<feature>.enable` with real configuration observations
- removed feature writes of the synthetic booleans
- deleted `modules/features/feature-presence-signals.nix`
- removed the signal aspect from live host includes, templates, and onboarding docs

Validation:
- `bash tests/scripts/new-host-skeleton-fixture-test.sh` -> pass
- `bash tests/scripts/run-validation-gates-fixture-test.sh` -> pass
- `./scripts/run-validation-gates.sh structure` -> pass
- `./scripts/run-validation-gates.sh server-example` -> pass
- `bash scripts/check-changed-files-quality.sh` -> pass
- `./scripts/check-docs-drift.sh` -> pass
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/antipattern-phase2-system` -> pass
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/antipattern-phase2-hm` -> pass
- `nix store diff-closures /tmp/antipattern-before-system /tmp/antipattern-phase2-system` -> empty
- `nix store diff-closures /tmp/antipattern-before-hm /tmp/antipattern-phase2-hm` -> empty

Notes:
- `./scripts/check-config-contracts.sh` still fails on the preexisting hardcoded-user policy rule:
  - `found hardcoded home-manager user 'higorprado' in tracked CI/script/docs paths`
  - `found hardcoded home-manager user 'ops' in tracked CI/script/docs paths`
- the Phase 2 replacement logic itself validated before reaching that preexisting failure class

### Phase 3: Unify Shell Ownership

Status: completed

Result:
- added a tracked `modules/users/ops.nix` so server/example hosts get fish from den's `user-shell` battery instead of the repo fish feature
- removed shell assignment and HM fish enablement from `modules/features/fish.nix`
- made den `user-shell` the sole owner of login-shell selection and fish enablement, while the repo fish aspect now only owns fish-specific UX/configuration

Validation:
- `git add modules/users/ops.nix` before Nix eval/builds -> required so `import-tree` sees the new user aspect
- `./scripts/run-validation-gates.sh structure` -> pass
- `./scripts/run-validation-gates.sh server-example` -> pass
- `./scripts/run-validation-gates.sh aurelius` -> pass
- `./scripts/check-docs-drift.sh` -> pass
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/antipattern-phase3-system` -> pass
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/antipattern-phase3-hm` -> pass
- `nix eval --json path:$PWD#nixosConfigurations.predator.config.users.users.higorprado.shell.pname` -> `"fish"`
- `nix eval --json path:$PWD#nixosConfigurations.aurelius.config.users.users.ops.shell.pname` -> `"fish"`
- `nix store diff-closures /tmp/antipattern-phase5-system /tmp/antipattern-phase3-system` -> empty
- `nix store diff-closures /tmp/antipattern-phase5-hm /tmp/antipattern-phase3-hm` -> empty

Notes:
- the new `ops` aspect is intentionally minimal; concrete account identity now lives in user aspects for both `higorprado` and `ops`
- this phase removed the remaining shell split without changing live closures

### Phase 4: Collapse Duplicated Host Metadata

Status: completed

Result:
- reduced `hardware/host-descriptors.nix` to script-only `integrations` metadata
- removed duplicated `system` and `role` fields from descriptors and onboarding fixtures/templates
- changed extension contracts to derive role from each host's runtime `custom.host.role` instead of mirroring it through the descriptor file
- kept host-name synchronization via descriptors while moving architecture/role authority back to host modules and hardware defaults

Validation:
- `./scripts/run-validation-gates.sh structure` -> pass
- `bash tests/scripts/new-host-skeleton-fixture-test.sh` -> pass
- `bash tests/scripts/dendritic-host-onboarding-contracts-fixture-test.sh` -> pass
- `bash tests/scripts/run-validation-gates-fixture-test.sh` -> pass
- `bash scripts/check-changed-files-quality.sh` -> pass
- `./scripts/check-docs-drift.sh` -> pass
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/antipattern-phase4-system` -> pass
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/antipattern-phase4-hm` -> pass
- `nix store diff-closures /tmp/antipattern-phase3-system /tmp/antipattern-phase4-system` -> empty
- `nix store diff-closures /tmp/antipattern-phase3-hm /tmp/antipattern-phase4-hm` -> empty

Notes:
- descriptors still intentionally own host-name membership for onboarding/registry scripts
- runtime `custom.host.role` remains the explicit validation signal until role can be removed entirely or derived from composition

### Phase 5: Migrate to Den-native User Ownership

Status: completed

Result:
- declared tracked fallback users under `den.hosts.<system>.<host>.users` for non-desktop hosts and generated host templates
- made `custom.user.name` a derived compatibility bridge from the sole declared host user via `modules/features/user-context.nix`
- removed tracked `custom.user.name` assignments from live host/hardware files and generated host fixtures/templates
- updated extension contracts and docs to treat host user declarations as the tracked source of truth

Validation:
- `bash tests/scripts/new-host-skeleton-fixture-test.sh` -> pass
- `./scripts/run-validation-gates.sh structure` -> pass
- `./scripts/run-validation-gates.sh server-example` -> pass
- `./scripts/run-validation-gates.sh aurelius` -> pass
- `./scripts/check-docs-drift.sh` -> pass
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/antipattern-phase5-system` -> pass
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/antipattern-phase5-hm` -> pass
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.custom.user.name` -> `higorprado`
- `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.custom.user.name` -> `ops`
- `nix store diff-closures /tmp/antipattern-phase2-system /tmp/antipattern-phase5-system` -> empty
- `nix store diff-closures /tmp/antipattern-phase2-hm /tmp/antipattern-phase5-hm` -> empty

Notes:
- private overrides may still `mkForce custom.user.name`; this remains the compatibility path until a den-native private-user override shape is introduced
- this slice made shell-ownership cleanup safer, but it did not remove `custom.user.name` consumers from feature modules

### Phase 6: Remove Repo-local Host-context Transport

Status: completed

Result:
- converted host-aware feature wiring to den-native parametric includes instead of the repo-local `config.host.*` / `_module.args.host` bridge
- removed `modules/features/home-manager-settings.nix` host forwarding
- deleted the `host-context` bridge aspect and removed it from live host compositions and host skeleton templates/fixtures
- moved the last non-module bridge use (`predator-tui`) into `modules/hosts/predator.nix`, leaving no live `config.host.*` consumers in tracked code

Validation:
- `rg -n "config\.host\.|_module\.args\.host" modules hardware home config pkgs tests scripts -g '*.nix' -g '*.sh'` -> no live code matches
- `./scripts/run-validation-gates.sh structure` -> pass
- `bash tests/scripts/new-host-skeleton-fixture-test.sh` -> pass
- `bash tests/scripts/run-validation-gates-fixture-test.sh` -> pass
- `bash scripts/check-changed-files-quality.sh` -> pass
- `./scripts/check-docs-drift.sh` -> pass
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/antipattern-phase6-system` -> pass
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/antipattern-phase6-hm` -> pass
- `nix store diff-closures /tmp/antipattern-phase5-system /tmp/antipattern-phase6-system` -> empty
- `nix store diff-closures /tmp/antipattern-phase5-hm /tmp/antipattern-phase6-hm` -> empty

Notes:
- den upstream expects host-owned Home Manager parametric config to match `{ host, user }`; using host-only matching there silently dropped HM config until corrected
- host-only parametric config that targets NixOS still needs `den.lib.take.exactly` to avoid duplicate matches across host/user contexts

### Phase 7: Clean Desktop/Home-path Consumers and Final Docs

Status: in progress

Completed so far:
- `modules/features/dms.nix` now reads the primary user's canonical `users.users.<name>.home` instead of constructing `/home/${userName}` manually

Validation for the completed slice:
- `./scripts/run-validation-gates.sh structure` -> pass
- `./scripts/check-docs-drift.sh` -> pass
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/antipattern-phase7-system` -> pass
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path -o /tmp/antipattern-phase7-hm` -> pass
- `nix store diff-closures /tmp/antipattern-phase6-system /tmp/antipattern-phase7-system` -> empty
- `nix store diff-closures /tmp/antipattern-phase6-hm /tmp/antipattern-phase7-hm` -> empty

Remaining in Phase 7:
- decide whether the desktop `ConditionUser` overrides should move to a user-scoped HM ownership path or stay on the compatibility bridge until the broader user-model cleanup
- rewrite the final architecture docs/priority files after the last user-path decisions settle
