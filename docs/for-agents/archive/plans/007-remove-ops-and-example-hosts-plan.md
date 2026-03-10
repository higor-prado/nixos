# Remove Ops and Example Hosts Plan

Date: 2026-03-09
Status: planned

## Goal

Remove the tracked fake-user/example-host surface cleanly:

1. remove `modules/users/ops.nix`
2. do not replace `ops` with another fake fallback user
3. remove the tracked example hosts `server-example` and `new-host`
4. update docs, tests, CI, and validation so only the real hosts remain
5. keep the host generator useful without reintroducing fake tracked users

This plan exists because the previous attempted slice drifted into the wrong
direction (`ops -> admin`). The correct direction is:

- no `ops`
- no `admin`
- no tracked example hosts that still need a fake user

## Current Situation

The repo currently has:

- real hosts:
  - `modules/hosts/predator.nix`
  - `modules/hosts/aurelius.nix`
- tracked example/scaffolding hosts:
  - `modules/hosts/server-example.nix`
  - `modules/hosts/new-host.nix`
- old fake fallback user:
  - `modules/users/ops.nix`

The user explicitly does not want:

- `ops`
- another substitute fake user like `admin`

So the only coherent end state is:

- keep real hosts only
- delete tracked example hosts
- remove the fake fallback user aspect entirely

## Important Constraint

There is currently a half-done, uncommitted failed attempt in the worktree.
Before implementation begins, the executing agent must inspect and clean up that
partial state instead of layering more changes on top of it.

At minimum, verify whether these partial changes are still present:

- `modules/users/admin.nix`
- deletion of `modules/users/ops.nix`
- edits in:
  - `modules/hosts/server-example.nix`
  - `modules/hosts/new-host.nix`
  - `scripts/check-config-contracts.sh`
  - `docs/for-agents/004-private-safety.md`
  - `docs/for-agents/current/003-antipattern-diag.md`
  - `docs/for-agents/plans/006-conditionuser-and-batteries-plan.md`
  - `docs/for-humans/01-philosophy.md`
  - `docs/for-humans/04-private-overrides.md`
  - `docs/for-humans/workflows/103-add-host.md`
  - fixture host files under `tests/fixtures/new-host-skeleton`

The unrelated local `flake.lock` modification must remain untouched.

## Target End State

After the refactor:

1. there is no `modules/users/ops.nix`
2. there is no `modules/users/admin.nix`
3. `server-example` and `new-host` no longer exist as tracked live hosts
4. validation topology only knows about:
   - `predator`
   - `aurelius`
5. docs no longer describe fake fallback users as active repo architecture
6. host generator still works, but uses the repo’s canonical real user aspect
   (`higorprado`) or an explicit replace-me default that does not require a
   tracked fake-user aspect

## Design Decisions

### 1. No fake replacement user

Do not introduce `admin`, `operator`, or any other replacement fake user.

Reason:
- the user explicitly rejected that direction
- once tracked example hosts are removed, there is no architectural need for a
  fake shared fallback user

### 2. Remove example hosts completely

The tracked example hosts are no longer needed because the repo already has two
real hosts.

Delete:
- `modules/hosts/server-example.nix`
- `modules/hosts/new-host.nix`
- `hardware/server-example/default.nix`
- `hardware/new-host/default.nix`
- their entries in `hardware/host-descriptors.nix`

### 3. Keep the generator, but stop pretending the repo still has example hosts

Keep:
- `scripts/new-host-skeleton.sh`
- `templates/new-host-skeleton`
- fixture tests for the generator

But change the generated host modules so they do not depend on a fake fallback
user aspect.

Recommended generator behavior:
- use the repo’s canonical tracked user aspect, `higorprado`, in generated
  output by default
- keep comments that tell the user to replace it when needed

Reason:
- the repo is explicitly a personal-machines repo
- there is already a documented tracked concrete-user exception
- generated files should stay valid and testable

This is better than:
- a fake fallback user, or
- generating invalid placeholder syntax that breaks fixture testing

## Execution Order

1. Phase 0: pre-flight cleanup and baseline capture
2. Phase 1: remove example hosts from live repo surface
3. Phase 2: remove `ops.nix` and any fake-user assumptions
4. Phase 3: retarget generator/templates/fixtures to canonical user default
5. Phase 4: update validation topology, CI, and contract checks
6. Phase 5: docs cleanup and closeout

## Phase 0: Pre-flight Cleanup and Baseline Capture

Purpose:
- stop stacking new edits on top of the aborted `ops -> admin` attempt
- capture before-state for diff testing

Required actions:
1. inspect `git status`
2. identify all partial `admin`/`ops` edits
3. clean those partial edits so the implementation starts from a coherent state
4. keep the unrelated `flake.lock` modification untouched
5. capture baselines:
   - `predator` system closure
   - `aurelius` eval baseline
   - current validation topology output

Validation:
```bash
git status --short
./scripts/run-validation-gates.sh structure
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/remove-ops-before-predator
./scripts/run-validation-gates.sh aurelius
```

Notes:
- local full build of `aurelius` from `x86_64-linux` is not a reliable signal;
  use the existing eval gate for Aurelius

Definition of done:
- no partial `admin` direction remains in the worktree
- baseline outputs are recorded in the progress log

## Phase 1: Remove Tracked Example Hosts

Delete the tracked example hosts from the live configuration surface.

Files to remove:
- `modules/hosts/server-example.nix`
- `modules/hosts/new-host.nix`
- `hardware/server-example/default.nix`
- `hardware/new-host/default.nix`

Also update:
- `hardware/host-descriptors.nix`
- `scripts/lib/validation_host_topology.sh`
- `scripts/run-validation-gates.sh`
- `.github/workflows/validate.yml`

Required behavior changes:
- remove the `server-example` validation stage entirely
- remove the `new-host` descriptor entry entirely
- reduce CI full-lane wording and jobs to the real remaining hosts

Validation:
```bash
./scripts/run-validation-gates.sh structure
./scripts/run-validation-gates.sh predator
./scripts/run-validation-gates.sh aurelius
nix store diff-closures /tmp/remove-ops-before-predator /tmp/remove-ops-after-phase1-predator
```

Diff expectation:
- `predator` should be unchanged
- `aurelius` eval-only gate should stay green

Commit target:
- `refactor: remove tracked example hosts`

## Phase 2: Remove `ops.nix` and Fake-user Assumptions

Delete:
- `modules/users/ops.nix`

Remove remaining active references to `ops` from:
- validation scripts
- living docs
- host templates/fixtures

Important distinction:
- historical progress logs may mention `ops` as past history
- active/living docs must stop describing `ops` as current architecture

Likely files:
- `scripts/check-config-contracts.sh`
- `docs/for-agents/004-private-safety.md`
- `docs/for-agents/current/003-antipattern-diag.md`
- `docs/for-humans/01-philosophy.md`
- `docs/for-humans/04-private-overrides.md`

Validation:
```bash
./scripts/run-validation-gates.sh structure
./scripts/check-repo-public-safety.sh
rg -n "\\bops\\b|modules/users/ops\\.nix" modules docs tests scripts .github hardware templates
```

Definition of done:
- no live code or living docs rely on `ops`
- only historical logs may still mention it as past work

Commit target:
- `refactor: remove fake fallback user model`

## Phase 3: Retarget Generator, Templates, and Fixtures

Keep the onboarding generator, but stop wiring it to fake fallback users.

Files:
- `scripts/new-host-skeleton.sh`
- `templates/new-host-skeleton/desktop-module.nix.tpl`
- `templates/new-host-skeleton/server-module.nix.tpl`
- fixture outputs under `tests/fixtures/new-host-skeleton`
- `docs/for-humans/workflows/103-add-host.md`

Recommended output shape:
- generated modules use `users.higorprado = { };` by default
- desktop generator comments show where to add `classes = [ "homeManager" ]`
- comments clearly say this is the personal-repo canonical default and should
  be replaced when appropriate

Reason:
- valid generated output
- no fake fallback user
- consistent with the repo’s actual two-host reality

Validation:
```bash
bash tests/scripts/new-host-skeleton-fixture-test.sh
./scripts/check-extension-contracts.sh
./scripts/check-docs-drift.sh
```

Commit target:
- `refactor: retarget host generator to canonical user`

## Phase 4: Update Validation and Contract Checks

Now that example hosts are gone, validation and simulation need a real server
reference host.

Required updates:

1. `scripts/check-config-contracts.sh`
   - replace `server-example` negative-control checks with `aurelius`

2. `scripts/check-extension-simulations.sh`
   - replace `server-example.extendModules` with `aurelius.extendModules`

3. `tests/scripts/run-validation-gates-fixture-test.sh`
   - remove `server-example` stage assertions

4. `scripts/lib/validation_host_topology.sh`
   - only `predator` and `aurelius`

5. `.github/workflows/validate.yml`
   - remove `server-example` full-lane job
   - fix descriptions and job names

Validation:
```bash
./scripts/run-validation-gates.sh structure
./scripts/run-validation-gates.sh predator
./scripts/run-validation-gates.sh aurelius
bash tests/scripts/run-validation-gates-fixture-test.sh
bash scripts/check-changed-files-quality.sh
```

Diff expectation:
- `predator` closure should stay unchanged
- `aurelius` remains eval-only in the validation runner unless a safe remote
  build path is explicitly introduced later

Commit target:
- `refactor: align validation with real host set`

## Phase 5: Docs Cleanup and Closeout

Clean living docs that still describe:
- `ops` as current fallback
- `server-example` as current reference host
- `new-host` as tracked scaffolding host

Likely files:
- `docs/for-humans/03-multi-host.md`
- `docs/for-agents/004-private-safety.md`
- `docs/for-agents/005-validation-gates.md`
- `docs/for-agents/current/003-antipattern-diag.md`
- `docs/for-agents/current/007-antipattern-remediation-progress.md`
  - historical notes may remain, but add a closeout note clarifying that
    `ops`, `server-example`, and `new-host` were later removed

Validation:
```bash
./scripts/check-docs-drift.sh
./scripts/check-repo-public-safety.sh
./scripts/run-validation-gates.sh structure
```

Commit target:
- `docs: remove fake-user and example-host references`

## Testing Discipline

Every phase must use real validation plus diffs.

### Mandatory checks

After each meaningful slice:
```bash
./scripts/run-validation-gates.sh structure
./scripts/check-docs-drift.sh
./scripts/check-repo-public-safety.sh
```

Host checks:
```bash
./scripts/run-validation-gates.sh predator
./scripts/run-validation-gates.sh aurelius
```

Generator/tests when touched:
```bash
bash tests/scripts/new-host-skeleton-fixture-test.sh
bash tests/scripts/run-validation-gates-fixture-test.sh
./scripts/check-extension-contracts.sh
./scripts/check-dendritic-host-onboarding-contracts.sh
```

### Diff-based checks

Primary no-regression diff:
```bash
nix build .#nixosConfigurations.predator.config.system.build.toplevel -o /tmp/remove-ops-after-<phase>-predator
nix store diff-closures /tmp/remove-ops-before-predator /tmp/remove-ops-after-<phase>-predator
```

For Aurelius:
- prefer eval gates locally
- if a remote build/test path is used, record it explicitly in the progress log

## Risks

1. Generator fixtures may fail if the new default user wiring is inconsistent.
   - Mitigation:
     - update templates and fixtures in the same commit

2. Validation scripts may still assume `server-example`.
   - Mitigation:
     - treat topology + script updates as one slice

3. Historical docs may still mention removed example hosts and fake users.
   - Mitigation:
     - add explicit closeout notes rather than rewriting every historical line

4. Empty removed hardware directories may keep failing host-descriptor sync.
   - Mitigation:
     - ensure the directories themselves are removed from the worktree, not just
       their `default.nix` files

## Definition of Done

This work is complete when:

1. `modules/users/ops.nix` does not exist
2. no replacement fake user aspect exists
3. `server-example` and `new-host` do not exist as tracked live hosts
4. validation topology contains only `predator` and `aurelius`
5. generator/templates/tests/docs are consistent with that reality
6. `predator` diff remains empty across the refactor
