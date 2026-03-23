# Aurelius GitHub Runner Plan

## Goal

Add a repo-native GitHub Actions runner on `aurelius` using a narrow published
owner, private token material, and proof on the real host path before any claim
that the runner is ready for workflow use.

## Scope

In scope:
- add a narrow NixOS owner for `services.github-runners.*`
- wire the owner cleanly into [aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)
- keep token material in private host overrides only
- define explicit runner labels, work directory, and runtime shape
- validate the local runner service on `aurelius`
- update living docs and the `050` roadmap only after runtime proof

Out of scope:
- editing GitHub repository workflow YAML
- registration automation outside the tracked runtime
- backup/restic
- broad CI redesign
- pushing any real token or repository URL into tracked files

## Current State

- There is no tracked GitHub runner owner under
  [modules/features/system](/home/higorprado/nixos/modules/features/system).
- The `aurelius` roadmap already reserves a dedicated Phase 6 for runner work in
  [050-aurelius-next-steps-dendritic-plan.md](/home/higorprado/nixos/docs/for-agents/plans/050-aurelius-next-steps-dendritic-plan.md).
- The healthy pattern for `aurelius` is now:
  - service semantics in feature owners
  - clean host composition in [aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)
  - private deployment facts in gitignored host overrides only
- The repo already has concrete examples of the desired service boundary:
  - [forgejo.nix](/home/higorprado/nixos/modules/features/system/forgejo.nix)
  - [prometheus.nix](/home/higorprado/nixos/modules/features/system/prometheus.nix)
  - [attic-publisher.nix](/home/higorprado/nixos/modules/features/system/attic-publisher.nix)
- The main risks for this slice are not structural but operational:
  - token scope
  - repository/owner binding
  - proving runner readiness without overclaiming

## Desired End State

- `aurelius` composes one narrow runner owner and nothing more in the host file.
- The runner owner owns:
  - `services.github-runners.*`
  - work directory shape
  - service-local runtime expectations
- The host owner only composes the feature.
- All deployment-specific facts stay private:
  - registration token file
  - repository or organization target if that should remain local
- The slice is only marked complete if:
  - the service is active on `aurelius`
  - the configured runner instance is visible in evaluated runtime
  - the runtime path is coherent with the intended labels/workdir
- The slice stays partial if the local service is healthy but the GitHub-side
  registration/use path is still unproved.

## Phases

### Phase 0: Baseline

Targets:
- [050-aurelius-next-steps-dendritic-plan.md](/home/higorprado/nixos/docs/for-agents/plans/050-aurelius-next-steps-dendritic-plan.md)
- [aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)

Changes:
- freeze the current runner-free baseline
- identify the minimal private facts the runner owner will need
- confirm that the slice will not push token/repo binding into tracked runtime

Validation:
- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-docs-drift.sh`

Diff expectation:
- no runtime change yet
- only a precise execution plan

Commit target:
- none

### Phase 1: Runner Owner

Targets:
- a new owner in `modules/features/system/`
- [aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)

Changes:
- add one narrow owner for GitHub runner support
- prefer native `services.github-runners.*`
- define only cohesive service semantics there:
  - enablement
  - service-local work directory
  - labels
  - any narrow runner runtime defaults
- expose only the minimum private facts as custom options, if needed:
  - token file
  - repository/org binding
- keep all token and deployment binding values out of tracked files
- wire `aurelius` to compose the owner cleanly in the existing grouped import list

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval .#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath`
- `nix eval --json .#nixosConfigurations.aurelius.config.services.github-runners`

Diff expectation:
- `aurelius` evaluates a runner service cleanly
- host-owner readability remains intact

Commit target:
- `feat(ci): add aurelius github runner owner`

### Phase 2: Local Runtime Proof

Targets:
- the new runner owner
- private host override for `aurelius` if required

Changes:
- deploy the runner to `aurelius`
- confirm service state and runtime directories
- prove local health without overclaiming GitHub-side readiness

Validation:
- `./scripts/run-validation-gates.sh all`
- `nh os test path:$PWD#aurelius --target-host aurelius --build-host aurelius -e passwordless`
- on `aurelius`:
  - `systemctl status` for the runner unit
  - `journalctl` for runner startup
  - inspect the configured work directory

Diff expectation:
- the runner is healthy on `aurelius`
- tracked runtime remains free of token leakage

Commit target:
- `feat(ci): deploy aurelius github runner`

### Phase 3: Completion Classification

Targets:
- [050-aurelius-next-steps-dendritic-plan.md](/home/higorprado/nixos/docs/for-agents/plans/050-aurelius-next-steps-dendritic-plan.md)
- [050-aurelius-next-steps-dendritic-plan-progress.md](/home/higorprado/nixos/docs/for-agents/current/050-aurelius-next-steps-dendritic-plan-progress.md)
- any human workflow doc touched by the slice

Changes:
- classify the slice honestly:
  - complete if local runtime plus GitHub-side registration/use are both proved
  - partial if only the local service path is proved
- document the exact proof commands
- do not document workflow usage that was not actually validated

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/check-repo-public-safety.sh`

Diff expectation:
- docs reflect exactly what is proved and what is still open

Commit target:
- `docs(ci): classify aurelius runner slice`

## Risks

- The runner token may be broader than necessary if we do not narrow it early.
- The service can look healthy locally while still not being usable from GitHub.
- It is easy to leak deployment binding into tracked files if the owner surface
  is not kept narrow.
- It is easy to overclaim success if “service active” is treated as enough proof.

## Definition of Done

- `aurelius` composes one narrow runner owner cleanly.
- No token, repository URL, or private deployment binding is tracked.
- The runner service is proved healthy on `aurelius`.
- The plan/progress docs state exactly whether GitHub-side usage is proved or
  still partial.
- `./scripts/run-validation-gates.sh all` passes.
- `./scripts/check-repo-public-safety.sh` passes.
