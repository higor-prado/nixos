# Remove Ops and Example Hosts Progress

Date: 2026-03-09
Status: completed

Plan:
- `docs/for-agents/plans/007-remove-ops-and-example-hosts-plan.md`

## Scope

Tracked phases:
1. pre-flight cleanup and baseline capture
2. remove tracked example hosts
3. remove fake fallback user model
4. retarget generator/templates/fixtures
5. update validation and contract checks
6. docs cleanup and closeout

## Baseline

Status: captured from `HEAD` at `b3a5bd1`

- clean baseline worktree created at `/tmp/nixos-remove-ops-baseline`
- baseline predator system build completed from the clean worktree
- baseline Aurelius eval gate completed from the clean worktree
- dirty worktree inspection confirmed the aborted `ops -> admin` direction had
  already been partly replaced by the correct no-`ops` / no-example-host
  direction, but docs and topology cleanup were still incomplete

## Phase Checklist

### Phase 0: Pre-flight Cleanup and Baseline Capture

Status: completed

Notes:
- confirmed there is no surviving `modules/users/admin.nix`
- preserved the unrelated local `flake.lock` modification untouched
- used the clean worktree at `/tmp/nixos-remove-ops-baseline` as the diff
  baseline for the live slice

### Phase 1: Remove Tracked Example Hosts

Status: completed

Notes:
- removed tracked live hosts:
  - `modules/hosts/server-example.nix`
  - `modules/hosts/new-host.nix`
  - `hardware/server-example/default.nix`
  - `hardware/new-host/default.nix`
- removed their descriptor entries and validation-stage references

### Phase 2: Remove Fake Fallback User Model

Status: completed

Notes:
- removed `modules/users/ops.nix`
- did not introduce any replacement fake user
- aligned living docs away from fake fallback-user language

### Phase 3: Retarget Generator, Templates, and Fixtures

Status: completed

Notes:
- generator templates and fixture outputs now use the canonical
  `users.higorprado = { };` shape
- no tracked example host remains part of the generated/live repo surface

### Phase 4: Update Validation and Contract Checks

Status: completed

Notes:
- validation topology now only declares `predator` and `aurelius`
- CI full-lane wording/jobs now target only the real hosts
- negative-control/extension simulation checks now use `aurelius`

### Phase 5: Docs Cleanup and Closeout

Status: completed

Validation:
- `./scripts/run-validation-gates.sh structure` -> pass
- `./scripts/run-validation-gates.sh predator` -> pass
- `./scripts/run-validation-gates.sh aurelius` -> pass
- `bash tests/scripts/new-host-skeleton-fixture-test.sh` -> pass
- `bash tests/scripts/run-validation-gates-fixture-test.sh` -> pass
- `bash scripts/check-changed-files-quality.sh` -> pass
- `./scripts/check-repo-public-safety.sh` -> pass
- `./scripts/check-docs-drift.sh` -> pass

Diff review:
- clean baseline predator closure:
  `/nix/store/a9ai7rdvw2ag5m3yz2wjj4wyasmfxps0-nixos-system-predator-26.05.20260308.9dcb002`
- post-change predator closure:
  `/nix/store/40c7ckivd38wmx2zdsgalifn1871c4lj-nixos-system-predator-26.05.20260308.9dcb002`
- `nix store diff-closures` showed only:
  - `unit-update-mdns-dns.service: ∅ → ε`
  - `unit-update-mdns-dns.timer: ∅ → ε`
  - `update-mdns: ∅ → ε`

Closeout notes:
- `check-config-contracts.sh` was tightened so absent optional attrs and
  historical plan/progress docs no longer cause false failures
- `check-desktop-composition-matrix.sh` was updated to the post-`core-options`
  repo shape and no longer imports the deleted `modules/features/core-options.nix`
