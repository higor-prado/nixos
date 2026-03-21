# Aurelius Quality Sweep

## Goal

Re-audit every slice that was previously treated as "done" in the `aurelius`
execution, remove any false-positive notion of completion, and bring the code,
active docs, and progress logs up to the same quality bar already expected by
this repository.

## Scope

In scope:
- re-audit the currently kept `aurelius` slices:
  - Docker foundation
  - remote dev baseline
  - cross-arch `dev-devenv` fix
  - Mosh
  - node exporter
  - Forgejo
- fix any runtime or documentation claim that is looser than the actual code
- remove or relocate temporary active-surface docs that do not belong in
  `docs/for-agents/current/`
- tighten plan/progress language so active docs stop overstating what is done
- revalidate the cleaned set with the repo's canonical gates

Out of scope:
- new Attic, Grafana, Prometheus, GitHub runner, or exit-node work
- backup/restic work
- speculative refactors with no concrete quality gain
- changing unrelated healthy runtime outside the `aurelius` scope

## Current State

- The active execution plan is
  [050-aurelius-next-steps-dendritic-plan.md](/home/higorprado/nixos/docs/for-agents/plans/050-aurelius-next-steps-dendritic-plan.md).
- The active progress log is
  [050-aurelius-next-steps-dendritic-plan-progress.md](/home/higorprado/nixos/docs/for-agents/current/050-aurelius-next-steps-dendritic-plan-progress.md).
- The current kept runtime slices are:
  - [aurelius.nix](/home/higorprado/nixos/modules/hosts/aurelius.nix)
  - [predator.nix](/home/higorprado/nixos/modules/hosts/predator.nix)
  - [dev-devenv.nix](/home/higorprado/nixos/modules/features/dev/dev-devenv.nix)
  - [mosh.nix](/home/higorprado/nixos/modules/features/system/mosh.nix)
  - [node-exporter.nix](/home/higorprado/nixos/modules/features/system/node-exporter.nix)
  - [forgejo.nix](/home/higorprado/nixos/modules/features/system/forgejo.nix)
- The current active docs surface also still contains
  [reference.md](/home/higorprado/nixos/docs/for-agents/current/reference.md),
  which is temporary external source material and not a repo-authored active
  progress log.
- Real problems already confirmed by review:
  - `devc` is broken on `aurelius` in the current kept runtime:
    - its default `DEVC_FLAKE=path:$HOME/nixos` assumes a repo clone under
      `~/nixos`
    - `aurelius` does not currently have that path
    - the feature therefore advertises a remote-dev tool that is not usable by
      default on the host where it was just added
  - the Mosh operator path was only partially validated:
    - `mosh-server` works on `aurelius`
    - the HM payload for predator built successfully
    - but the real `amdev` operator workflow was not proved from an activated
      predator runtime
  - `forgejo.nix` is local-only but currently encodes `ROOT_URL = "http://aurelius:3000/"`,
    which does not match the validated access path
  - the progress log still treats Slice 4 as fully clean even though its access
    semantics are incomplete
  - Slice 2 text still says Mosh was explicitly not added, even though that same
    slice did add and validate Mosh
  - `reference.md` still contains generic anti-pattern examples and should not
    stay in the active `current/` surface as if it were repo-owned live guidance
  - `dev-devenv.nix` now uses `lib.mkForce` for `xdg.configFile."direnv/direnvrc".source`,
    but there is no competing tracked owner for that path, so the override
    strength likely exceeds what is actually needed

## Desired End State

- No slice remains labeled "done" unless both the code and the active docs
  describe it accurately.
- `forgejo.nix` matches its real validated state:
  - either truly local-only with coherent URL semantics
  - or explicitly deferred until a real access model is introduced
- `devc` either works by default on `aurelius` or is explicitly removed from
  the kept remote-dev slice until it has a real repo-native default model
- The Mosh slice is either fully proved from the real predator operator path or
  downgraded from "done" to "partially validated"
- The active `050` plan and progress log describe only what is actually true
  today.
- `docs/for-agents/current/` contains only genuine active progress material, not
  generic external reference dumps.
- `dev-devenv.nix` uses the narrowest correct ownership/override strength.
- The surviving runtime remains structurally clean and fully validated.

## Phases

### Phase 0: Findings Freeze

Targets:
- [050-aurelius-next-steps-dendritic-plan.md](/home/higorprado/nixos/docs/for-agents/plans/050-aurelius-next-steps-dendritic-plan.md)
- [050-aurelius-next-steps-dendritic-plan-progress.md](/home/higorprado/nixos/docs/for-agents/current/050-aurelius-next-steps-dendritic-plan-progress.md)
- [reference.md](/home/higorprado/nixos/docs/for-agents/current/reference.md)

Changes:
- record the concrete quality failures discovered in the re-audit
- stop treating temporary source material as active canonical guidance
- freeze which slices are currently "kept but still need correction"

Validation:
- read active plan, log, and temporary source material together
- verify the active surface still follows the docs organization rules

Diff expectation:
- plan-only audit baseline

Commit target:
- `docs(aurelius): record quality sweep baseline`

### Phase 1: Fix Runtime Semantics

Targets:
- [forgejo.nix](/home/higorprado/nixos/modules/features/system/forgejo.nix)
- [dev-devenv.nix](/home/higorprado/nixos/modules/features/dev/dev-devenv.nix)

Changes:
- fix the Forgejo local-only semantics so service URL settings match the
  validated access path instead of implying remote usability that does not
  exist yet
- fix `devc` so the remote-dev slice does not depend on an untracked
  host-specific clone layout, or drop `dev-devenv` from the kept aurelius slice
  until a clean default exists
- reclassify the Mosh slice honestly unless the full predator -> aurelius
  operator path is actually proved
- re-check whether `dev-devenv.nix` really needs `lib.mkForce`; if not, reduce
  it to the narrowest correct assignment
- avoid any new host-owner churn while doing these fixes

Validation:
- `./scripts/run-validation-gates.sh structure`
- `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath`
- `ssh aurelius 'devc help'`
- `ssh aurelius 'devc list'` or another exact proof command for the corrected
  default behavior
- if Mosh remains in the kept done set, prove the actual predator-side operator
  path or explicitly record that only server/build-level validation exists
- `ssh aurelius "systemctl is-active forgejo.service"`
- `ssh aurelius "curl -I --max-time 5 http://127.0.0.1:3000 | sed -n '1,5p'"`
- if Forgejo remains local-only, confirm the service URL settings now describe
  that reality coherently

Diff expectation:
- runtime slices become semantically correct, not just operational

Commit target:
- `fix(aurelius): tighten local-only runtime semantics`

### Phase 2: Fix Active Docs and Logs

Targets:
- [050-aurelius-next-steps-dendritic-plan.md](/home/higorprado/nixos/docs/for-agents/plans/050-aurelius-next-steps-dendritic-plan.md)
- [050-aurelius-next-steps-dendritic-plan-progress.md](/home/higorprado/nixos/docs/for-agents/current/050-aurelius-next-steps-dendritic-plan-progress.md)
- [106-deploy-aurelius.md](/home/higorprado/nixos/docs/for-humans/workflows/106-deploy-aurelius.md)
- [reference.md](/home/higorprado/nixos/docs/for-agents/current/reference.md)

Changes:
- remove contradictory or overstated progress claims:
  - Slice 2 Mosh contradiction
  - Slice 4 cleanliness/completeness overstatement
- update the active plan so already-implemented slices are clearly separated
  from deferred or still-incomplete ones
- decide whether `reference.md` should be:
  - deleted after extraction
  - moved out of `current/`
  - or explicitly marked as non-canonical raw input
- ensure human-facing docs do not imply any `aurelius` service URL that was not
  actually validated from its real consumer path

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/check-repo-public-safety.sh`
- `rg` checks for stale or contradictory wording in the touched docs

Diff expectation:
- active docs stop overstating completion and stop carrying generic poison in
  the active surface

Commit target:
- `refactor(docs): align aurelius active docs with runtime reality`

### Phase 3: Final Revalidation and Commit Boundary

Targets:
- all touched runtime and docs files from phases 1 and 2

Changes:
- rerun the full repo gates after the semantic and documentation corrections
- confirm the surviving slices still satisfy the quality bar from the `050`
  plan
- confirm no active doc still teaches a shape that the repo would reject

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/check-repo-public-safety.sh`
- `./scripts/run-validation-gates.sh all`
- `nix eval --raw path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `nix eval --raw path:$PWD#nixosConfigurations.aurelius.config.system.build.toplevel.drvPath`

Diff expectation:
- the kept `aurelius` work is not only functional, but also honestly described
  and structurally clean

Commit target:
- `refactor(aurelius): finish quality sweep`

## Risks

- Overcorrecting could discard healthy slices instead of fixing only the false
  completion claims.
- Undercorrecting would leave active docs and runtime semantics subtly
  misleading again.
- `reference.md` is useful as raw input, but dangerous if left in the active
  surface without a very explicit non-canonical status.

## Definition of Done

- Every previously "done" `aurelius` slice has been re-audited against the same
  quality bar used for healthy repo runtime.
- No active runtime slice remains semantically misleading.
- No active doc remains contradictory, overstated, or generically wrong for
  this repo.
- `docs/for-agents/current/` contains only material that genuinely belongs in
  the active surface.
- The corrected set passes the repo's canonical validation gates.
