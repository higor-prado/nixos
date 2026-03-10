# Validation Gates

## Quick check (structural, <2 min)

```bash
./scripts/run-validation-gates.sh
```

## Nix eval check

```bash
nix eval .#nixosConfigurations.predator.config.system.build.toplevel.drvPath
```

## Full build

```bash
nix build .#nixosConfigurations.predator.config.system.build.toplevel \
  -o /tmp/predator-new
```

## Diff against baseline

```bash
nix run nixpkgs#nvd -- diff /tmp/predator-baseline /tmp/predator-new
```

## Individual gate scripts

| Script | Checks |
|--------|--------|
| `check-desktop-capability-usage.sh` | Legacy desktop selector references stay out of active Nix code |
| `check-option-declaration-boundary.sh` | Options declared only in allowed locations |
| `check-flake-pattern.sh` | Flake input naming and wiring policy |
| `check-config-contracts.sh` | Role/feature/username-indirection invariants |
| `check-extension-contracts.sh` | Host descriptor/module contracts |
| `check-dendritic-host-onboarding-contracts.sh` | Host descriptor onboarding contract shape |
| `check-desktop-composition-matrix.sh` | Desktop compositions eval correctly |
| `check-extension-simulations.sh` | Synthetic host extension eval checks |
| `check-validation-source-of-truth.sh` | Shared script inventory and CI/stage routing contracts |
| `check-docs-drift.sh` | Living docs only reference paths that still exist |

## Shared Script Boundary

Top-level tracked scripts are intentionally split into three categories:

- `gate-runner`
  - `run-validation-gates.sh`
- `gate-check`
  - scripts directly invoked by `run-validation-gates.sh`
- `shared-aux`
  - shared tools that are intentionally tracked even when they are not part of the canonical gate runner

The authoritative registry is:

```text
tests/pyramid/shared-script-registry.tsv
```

The authoritative declared host-stage topology for shared validation is:

```text
scripts/lib/validation_host_topology.sh
```

Current documented shared auxiliary tools:

- `audit-system-up-to-date.sh`
  - optional local audit/report generator; uses audit-only leaf checks such as `check-declarative-paths.sh`, `check-flake-tracked.sh`, `check-nix-deprecations.sh`, and `check-repo-public-safety.sh`
- `new-host-skeleton.sh`
  - shared host onboarding generator; validated by extension contracts and fixture tests
- `report-maintainability-kpis.sh`
  - shared KPI/report helper for script count, LOC, and repo-health snapshots
- `check-changed-files-quality.sh`
  - targeted shell/script hygiene check used during script-heavy refactors

## Validation layers

| Layer | Budget | Runs |
|-------|--------|------|
| A | 120s | On every PR: structural/static checks |
| B | 900s | On feature changes: nix eval/build matrix |
| C | 1500s | Optional local runtime smoke outside the canonical gate runner |

`check-runtime-smoke.sh` is intentionally a predator-scoped local desktop-session
check. It is retained as a tracked auxiliary tool, not as a stage of
`run-validation-gates.sh`.
This is a deliberate local-tool exception, not part of the canonical shared
validation topology.

Because it remains a tracked top-level script, its basic CLI contract still
stays covered by:

```bash
bash tests/scripts/gate-cli-contracts-test.sh
```

## When to run what

- Before any commit: `run-validation-gates.sh`
- After adding a feature: `nix eval` + `run-validation-gates.sh`
- After contract-sensitive changes: `check-config-contracts.sh`
- Before merge: `run-validation-gates.sh all`
