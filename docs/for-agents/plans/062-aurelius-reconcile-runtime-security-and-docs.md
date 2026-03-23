# Aurelius Runtime, Security, and Docs Reconciliation Plan

## Goal

Bring the current `aurelius` stack back to a clean, reproducible, and
repo-consistent state by fixing three classes of problems that now diverge from
each other:

1. private runtime shape vs tracked examples/docs
2. service-owner shape vs dendritic ownership expectations
3. operational access/sudo surface vs minimum necessary privilege

The target is not “make it work somehow”. The target is:
- reproducible after host rebuild
- understandable from tracked docs
- private facts kept private
- service/runtime owners shaped cleanly enough to survive long-term maintenance

## Scope

In scope:
- reconcile Attic and GitHub runner tracked modules with the actual private
  overrides now in use
- narrow the `aurelius` sudo surface to the minimum set actually needed for the
  deploy/recovery workflows
- fix incorrect tracked bootstrap and private-override docs
- decide whether the current Attic publisher shape is acceptable or should be
  reworked again
- prove final runtime behavior after the cleanup
- keep secrets and concrete private bindings out of tracked files

Out of scope:
- replacing Attic with another cache
- removing Grafana / Forgejo / runner / Prometheus
- broad redesign of the repo’s private override system
- unrelated worktree dirt (`flake.lock`, user-local feature work)

## Why This Plan Exists

A review of the latest Aurelius work surfaced a mixed state:

- the runtime is largely functional
- private overrides do exist and do carry real deployment facts
- but tracked docs/examples no longer describe the real wiring shape
- and one private override now grants more `sudo` than is justified

That means the system is not in a clean “declarative and comprehensible”
condition yet, even if most services currently run.

## Current State

### Good

- no private tokens or obvious secrets are tracked
- tracked safety/docs gates pass:
  - `./scripts/check-repo-public-safety.sh`
  - `./scripts/check-docs-drift.sh`
  - `./scripts/run-validation-gates.sh structure`
- real private overrides exist for:
  - GitHub runner on `aurelius`
  - Attic producer/consumer on `predator`
- narrow service owners now exist for:
  - Grafana
  - Docker health check
  - disk usage alert
  - Tailscale exit-node capability

### Bad

1. **Tracked docs/examples do not match the private runtime shape**
   - tracked docs/examples still teach:
     - `custom.githubRunner.*`
     - `custom.attic.client.*`
     - `custom.attic.publisher.*`
   - private runtime now actually uses:
     - `services.github-runners.aurelius.*`
     - `nix.settings.extra-substituters`
     - `nix.settings.extra-trusted-public-keys`
     - `environment.etc."attic/publisher.conf"`

2. **Attic publisher shape drifted into a weaker owner design**
   - runtime now depends on:
     - `/etc/attic/publisher.conf`
     - `source`-ing shell config as root
     - runtime `mkdir -p` instead of explicit owner-managed state
     - `|| true` suppressing push failures
   - this may still work, but it is harder to reason about and easier to leave
     half-broken without noticing

3. **The `aurelius` private sudo surface is too broad**
   - current private override grants `NOPASSWD` for:
     - `nix`
     - `nix-env`
     - `nh`
     - `switch-to-configuration`
   - only a subset of this is likely necessary for the actual host workflow

4. **Bootstrap docs contain incorrect or misleading instructions**
   - Attic docs refer to a nonexistent service-level verification path for the
     publisher
   - examples describe old/private wiring shapes that no longer match runtime

## Desired End State

- tracked docs and tracked examples match the real private override shape
- Attic private wiring is either:
  - restored to a cleaner option-based owner contract
  - or documented precisely enough that the current file-based contract is
    explicit, validated, and service-owned
- `aurelius` private sudo rules are reduced to the minimum actually needed
- recovery after rebuild is understandable from tracked docs plus gitignored
  private files, not tribal memory
- all affected services are re-proved after cleanup:
  - Attic
  - GitHub runner
  - Grafana
  - SSH/deploy path

## Decision Rule for Attic

Before editing, make an explicit decision between two acceptable shapes:

### Option A: restore tracked option contract

Use narrow tracked options again for:
- Attic client endpoint/public key
- Attic publisher endpoint/cache/token file

Pros:
- clearer module contract
- examples/docs stay close to implementation
- less shell/file indirection

Cons:
- reintroduces narrow module options

### Option B: keep file-based private runtime contract

Keep:
- `environment.etc."attic/publisher.conf"`
- direct `nix.settings.*` wiring in private override

Pros:
- fewer custom tracked options
- private binding stays obviously private

Cons:
- tracked examples/docs must be rewritten around the real NixOS options
- publisher owner must be hardened so it does not feel like shell glue

This plan is complete only when one option is chosen explicitly and the rest of
the repo aligns to it.

Decision taken during execution:
- use **Option A**
- restore the narrow tracked option contract for Attic
- keep private facts private, but stop teaching undocumented raw private wiring

## Phases

### Phase 0: Freeze the Real Contract

Targets:
- `modules/features/system/attic-client.nix`
- `modules/features/system/attic-publisher.nix`
- `modules/features/system/github-runner.nix`
- `private/hosts/aurelius/services.nix.example`
- `private/hosts/predator/services.nix.example`
- `docs/for-humans/workflows/105-private-overrides.md`
- `docs/for-humans/workflows/107-aurelius-service-bootstrap.md`

Changes:
- record the current real private-wiring contract exactly
- decide whether Attic should keep the new file-based contract or move back to a
  narrow tracked option contract
- identify every tracked example/doc that still describes the old shape

Validation:
- `rg -n "custom\\.githubRunner|custom\\.attic|attic/publisher.conf|services\\.github-runners\\.aurelius|extra-substituters|extra-trusted-public-keys" modules docs private -S`
- `./scripts/check-docs-drift.sh`

Commit target:
- none

### Phase 1: Fix the Tracked Contract Surface

Targets:
- Attic and runner tracked modules
- tracked examples and human docs

Changes:
- make tracked code and tracked docs agree on one contract
- if Attic keeps private direct wiring:
  - examples/docs must stop teaching `custom.attic.*`
  - owner comments and runbooks must describe the actual private shape
- if Attic restores tracked options:
  - reintroduce narrow options cleanly
  - update the private examples to match
- update runner examples/docs to teach the actual private shape:
  - `services.github-runners.aurelius.*`

Validation:
- `./scripts/check-docs-drift.sh`
- `./scripts/check-repo-public-safety.sh`
- `./scripts/run-validation-gates.sh structure`

Commit target:
- `refactor(aurelius): reconcile private wiring contracts`

### Phase 2: Harden the Attic Publisher Owner

Targets:
- `modules/features/system/attic-publisher.nix`
- Attic bootstrap docs

Changes:
- remove silent failure where possible
- make state/layout expectations explicit
- if file-based config remains:
  - make the expected file shape explicit in tracked examples/docs
  - make validation/logging explicit enough to catch broken publish
- decide whether `post-build-hook` should stay or whether a cleaner declarative
  wrapper is needed

Validation:
- `./scripts/run-validation-gates.sh structure`
- prove a real build still publishes to Attic
- prove the proof path is queryable from the remote cache

Commit target:
- `fix(attic): harden publisher contract`

### Phase 3: Narrow Aurelius Sudo

Targets:
- `private/hosts/aurelius/default.nix`
- Aurelius bootstrap/recovery docs

Changes:
- audit which `NOPASSWD` rules are actually needed for:
  - remote deploy
  - switch/profile update
  - recovery tasks
- remove broader rules that are not required
- keep the minimum set that still supports the real operator workflow

Validation:
- remote deploy path still works:
  - `nh os test path:$PWD#aurelius --target-host aurelius --build-host aurelius -e passwordless`
- no unnecessary `NOPASSWD` commands remain

Commit target:
- none tracked if private-only, but record the result in docs/progress

### Phase 4: Re-Prove Runtime After Cleanup

Targets:
- Aurelius service surface
- roadmap/progress docs

Changes:
- re-run runtime proof for the affected surfaces:
  - Attic
  - GitHub runner
  - Grafana
  - SSH/deploy path
- fix any docs that still overclaim or describe obsolete bootstrap

Validation:
- `./scripts/check-repo-public-safety.sh`
- `./scripts/check-docs-drift.sh`
- `./scripts/run-validation-gates.sh all`
- runtime probes from the real host paths that matter

Commit target:
- `docs(aurelius): reconcile runtime proof and recovery docs`

## Risks

- Overcorrecting Attic could re-break a currently working cache path.
- Narrowing sudo too aggressively could break the deploy path and slow recovery.
- Rewriting docs without re-proving runtime would just create a new false-done
  layer.
- Reintroducing broad custom options would solve doc drift while regressing the
  ownership surface.

## Definition of Done

This plan is complete only when all of the following are true:

1. Tracked docs/examples and real private wiring describe the same contract.
2. Attic publisher shape is explicit and defensible, not “works if you know the
   hidden file.”
3. `aurelius` private sudo rules are narrowed to the minimum needed.
4. No private data is tracked.
5. Runtime proof is rerun after the cleanup, not inherited from before it.
6. A fresh reader can understand how to rebuild Aurelius from:
   - tracked host/service owners
   - tracked runbooks/examples
   - gitignored private override files
