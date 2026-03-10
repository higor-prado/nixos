# Antipattern First-Wave Remediation Plan

Date: 2026-03-09
Owner: Codex + user
Status: ready for execution

Scope:
- fix only the first four items from
  `docs/for-agents/current/004-antipattern-priority-order.md`

Items in scope:
1. `host.descriptor` dead mirror
2. theme leakage in `home-manager-settings`
3. `check-runtime-smoke.sh` shared-boundary ambiguity
4. validation topology hardcoded to specific hosts

Non-goals:
- no hybrid-user-model rewrite
- no `core-options.nix` split yet
- no host-context schema rewrite yet
- no removal of validation-only feature flags in this wave

## Execution Rules

Each slice must end with:

1. code/doc change
2. validation
3. before/after diff review where applicable
4. progress log update
5. commit

When a change can affect Nix behavior, capture before/after outputs and compare:

```bash
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/predator-before
nix build .#nixosConfigurations.predator.config.home-manager.users.<user>.home.path -o /tmp/hm-before

# apply change

nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/predator-after
nix build .#nixosConfigurations.predator.config.home-manager.users.<user>.home.path -o /tmp/hm-after

nix store diff-closures /tmp/predator-before /tmp/predator-after
nix store diff-closures /tmp/hm-before /tmp/hm-after
```

Mandatory structural checks after each meaningful slice:

```bash
./scripts/run-validation-gates.sh structure
./scripts/check-docs-drift.sh
```

Mandatory for shell-script changes:

```bash
shellcheck <changed scripts>
bash scripts/check-changed-files-quality.sh
./scripts/report-maintainability-kpis.sh --skip-gates
```

## Item 1: Remove `host.descriptor` Dead Mirror

Goal:
- remove the lower-level `host.descriptor` mirror if it truly has no live consumer
- keep `hardware/host-descriptors.nix` as the single descriptor source for scripts

Targets:
- `modules/features/core-options.nix`
- `modules/hosts/*.nix`
- templates/fixtures/docs that currently emit or describe `host.descriptor`

Expected change:
- delete `options.host.descriptor`
- remove `host.descriptor = { ... };` blocks from host modules
- update generated host templates and onboarding docs
- update any tests/fixtures that still expect the mirror

Validation:
- `./scripts/run-validation-gates.sh structure`
- `bash tests/scripts/new-host-skeleton-fixture-test.sh`
- any affected fixture tests
- repo-wide search confirms no tracked live consumers remain:
  - `rg -n "host\\.descriptor" modules hardware pkgs scripts docs tests`

Diff review:
- mostly documentation/template/contract diffs
- if any Nix outputs change, treat that as unexpected and investigate

Risk:
- low, as long as no hidden runtime/module consumer exists

Commit target:
- `refactor: remove dead host descriptor mirror`

## Item 2: Move Catppuccin Framework Wiring Out of `home-manager-settings`

Goal:
- keep `home-manager-settings` purely as HM plumbing
- move theme-provider import responsibility to theme ownership

Targets:
- `modules/features/home-manager-settings.nix`
- `modules/features/theme.nix`
- docs describing HM context propagation and theme ownership

Expected change:
- remove `config.host.inputs.catppuccin.homeModules.catppuccin` from `home-manager-settings`
- import/inject Catppuccin from `theme.nix` or another theme-owned location
- keep `_module.args.host` in `home-manager-settings`

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix build .#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `nix build .#nixosConfigurations.predator.config.system.build.toplevel`
- `nix store diff-closures` before/after
- optional targeted eval:
  - `nix eval --json path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.catppuccin`

Diff review:
- HM closure diff should be empty or explainable
- theme behavior should not silently disappear

Risk:
- low to medium
- main risk is breaking HM evaluation if Catppuccin options lose their module import

Commit target:
- `refactor: keep home-manager settings framework-only`

## Item 3: Clarify `check-runtime-smoke.sh` Boundary

Decision required at execution time:
- either make it explicitly predator-scoped
- or parameterize it by host and keep it as a shared tool

Recommended default:
- make the scope explicit first, not generic by force

Goal:
- eliminate ambiguity between “shared auxiliary tool” and “host-specific runtime smoke”

Targets:
- `scripts/check-runtime-smoke.sh`
- `scripts/run-validation-gates.sh`
- `tests/pyramid/shared-script-registry.tsv`
- `docs/for-agents/005-validation-gates.md`
- possibly `scripts/check-validation-source-of-truth.sh`

Option A: explicit host-scoped shared tool
- rename/document it as predator runtime smoke
- keep it top-level only if the repo intentionally treats predator as canonical desktop runtime target

Option B: parameterized shared tool
- add `--host <name>`
- stop hardcoding predator in eval calls
- keep `runtime-smoke` entrypoint passing an explicit default host

Validation:
- `shellcheck` on changed scripts
- `bash scripts/check-changed-files-quality.sh`
- `./scripts/check-validation-source-of-truth.sh`
- `./scripts/run-validation-gates.sh structure`
- `./scripts/report-maintainability-kpis.sh --skip-gates`

Diff review:
- registry/docs/source-of-truth diffs must align
- no hidden broadening of the canonical validation surface

Risk:
- medium
- mostly policy/boundary risk, not build risk

Commit target:
- `refactor: clarify runtime smoke ownership`

## Item 4: Reduce Hardcoded Host Validation Topology

Goal:
- reduce direct host-name wiring in shared validation scripts
- move toward a smaller number of declared topology sources

Targets:
- `scripts/run-validation-gates.sh`
- `scripts/check-config-contracts.sh`
- `scripts/report-maintainability-kpis.sh`
- `hardware/host-descriptors.nix`
- `tests/pyramid/config-test-pyramid.json`
- possibly a small shared data file if one is truly needed

Preferred approach:
- define one explicit validation host set
- derive runner/check behavior from that set instead of repeating `predator`, `server-example`, `aurelius`

Important constraint:
- do not over-engineer this into a new framework
- aim for fewer hand-edited host lists, not more abstraction for its own sake

Validation:
- `shellcheck` on changed scripts
- `bash tests/scripts/run-validation-gates-fixture-test.sh`
- `bash tests/scripts/gate-cli-contracts-test.sh`
- `./scripts/check-validation-source-of-truth.sh`
- `./scripts/run-validation-gates.sh structure`
- target-specific gates for any changed host stages

Diff review:
- CLI behavior of `run-validation-gates.sh` should remain stable unless intentionally changed
- fixture tests should prove stage orchestration still matches policy

Risk:
- medium
- touches the canonical validation runner and test contracts

Commit target:
- `refactor: reduce hardcoded validation host topology`

## Recommended Order

1. Item 1: remove `host.descriptor`
2. Item 2: remove theme leakage from HM plumbing
3. Item 3: clarify runtime smoke boundary
4. Item 4: reduce hardcoded validation topology

Rationale:
- 1 and 2 are the cleanest ownership wins with relatively small blast radius
- 3 is mostly a boundary decision
- 4 is best after 3, since runtime-smoke classification affects the topology model

## Success Criteria

This first wave is complete when:

- `host.descriptor` no longer exists as dead mirrored metadata
- `home-manager-settings` contains only HM framework/plumbing concerns
- `check-runtime-smoke.sh` has an explicit and documented boundary
- shared validation scripts no longer require repeated hardcoded host names in multiple places
- structure/docs/script validation all pass after each slice
