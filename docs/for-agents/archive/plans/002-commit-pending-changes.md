# Commit Plan: All Pending Working-Tree Changes

## Goal

Commit all pending working-tree changes in focused, logically-separated commits
that pass structure gates after each one.

## Current State

14 modified files + 2 new files in the working tree, spanning 5 distinct
concerns introduced over multiple sessions.

### Indentation regression

Three scripts were accidentally converted from **2-space** to **tab** indentation
during editing. The committed repo convention is:

- `scripts/*.sh` → 2-space indent (39 of 41 scripts)
- `tests/scripts/*.sh` → 2-space indent (4 of 6 test fixtures)

Exceptions (already committed with tabs): `check-config-contracts.sh`,
`run-validation-gates-fixture-test.sh`.

**Must fix before committing:**

| File                                                      | Current | Should be |
| --------------------------------------------------------- | ------- | --------- |
| `scripts/check-flake-pattern.sh`                          | tabs    | 2-space   |
| `scripts/check-validation-source-of-truth.sh`             | tabs    | 2-space   |
| `scripts/run-validation-gates.sh`                         | tabs    | 2-space   |
| `tests/scripts/check-flake-pattern-fixture-test.sh` (new) | tabs    | 2-space   |

## Scope

In scope:

- All 14 modified + 2 new files in `git status --short`
- Pre-commit indentation fix for the 4 files above
- Plan file archival after completion

Out of scope:

- Any new feature work
- Changes to files not currently modified
- Updating `999-lessons-learned.md` (PT lesson #51 is still in Portuguese in
  the committed HEAD; translating it is a separate concern)

## Phases

### Phase 0: Fix indentation regression

Targets:

- `scripts/check-flake-pattern.sh`
- `scripts/check-validation-source-of-truth.sh`
- `scripts/run-validation-gates.sh`
- `tests/scripts/check-flake-pattern-fixture-test.sh`

Changes:

- Convert all leading tabs to 2-space indentation in the 4 files above.
- Only indentation — no logic changes.

Validation:

```bash
for f in scripts/check-flake-pattern.sh scripts/check-validation-source-of-truth.sh \
         scripts/run-validation-gates.sh tests/scripts/check-flake-pattern-fixture-test.sh; do
  tabs=$(tr -cd '\t' < "$f" | wc -c)
  echo "$f: $tabs tabs"
done
# All should show 0
bash scripts/run-validation-gates.sh structure
```

No commit — this is a pre-commit fix folded into the relevant commits below.

### Phase 1: fix(i18n): translate Portuguese comments to English

Targets:

- `modules/hosts/predator.nix` — nix-ld comment block PT→EN
- `hardware/cerebelo/default.nix` — boot comment PT→EN

Changes:

- Translate the nix-ld risk/comment block in predator.nix from Portuguese to
  English (already done in working tree).
- Translate the boot comment in cerebelo/default.nix from Portuguese to English
  (already done in working tree).

Validation:

```bash
bash scripts/run-validation-gates.sh structure
```

Diff expectation:

- predator.nix: ~25 lines changed (comment block only)
- cerebelo/default.nix: 2 lines changed

Commit target:

- `fix(i18n): translate Portuguese comments to English in predator and cerebelo`

### Phase 2: feat(neovim): add stale embedded process cleanup service

Targets:

- `modules/features/dev/editors-neovim.nix`

Changes:

- New `nvimStaleProcessCleanup` shell script that detects and kills stale
  nvim `--embed` processes with deleted TTYs under kitty graphical scope.
- New `systemd.user.services.nvim-stale-process-cleanup` oneshot service.
- New `systemd.user.timers.nvim-stale-process-cleanup` periodic timer
  (every 2 minutes).

Validation:

```bash
bash scripts/run-validation-gates.sh structure
nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath
```

Diff expectation:

- ~130 lines added (Python script + service/timer Nix blocks)

Commit target:

- `feat(neovim): add stale embedded process cleanup service and timer`

### Phase 3: fix(audit): make nix-ld interpreter configurable for testability

Targets:

- `scripts/audit-nix-ld-usage.sh`
- `tests/scripts/audit-nix-ld-usage-fixture-test.sh`

Changes:

- Replace hardcoded `/lib64/ld-linux-x86-64.so.2` with
  `${AUDIT_NIX_LD_INTERPRETER:-/lib64/ld-linux-x86-64.so.2}` so fixture tests
  can use a fake interpreter.
- Update fixture test to create a fake nix-ld symlink and pass
  `AUDIT_NIX_LD_INTERPRETER` to the script under test.

Validation:

```bash
bash tests/scripts/audit-nix-ld-usage-fixture-test.sh
bash scripts/run-validation-gates.sh structure
```

Diff expectation:

- audit-nix-ld-usage.sh: 1 line changed
- fixture test: ~15 lines added (fake interpreter setup + env var passing)

Commit target:

- `fix(audit): make nix-ld interpreter configurable for testability`

### Phase 4: fix(validation): capture short-form flake inputs in kebab-case check

Targets:

- `scripts/check-flake-pattern.sh` — AWK fix (from Phase 0: indentation already
  corrected to 2-space)
- `tests/scripts/check-flake-pattern-fixture-test.sh` — **new** (from Phase 0:
  indentation already corrected to 2-space)
- `scripts/run-validation-gates.sh` — wire in new test (from Phase 0:
  indentation already corrected to 2-space)
- `tests/scripts/run-validation-gates-fixture-test.sh` — add stub + assert
- `scripts/check-validation-source-of-truth.sh` — add `test-fixture` category
  (from Phase 0: indentation already corrected to 2-space)
- `tests/pyramid/shared-script-registry.tsv` — register new test
- `docs/for-agents/005-validation-gates.md` — document new test
- `docs/for-agents/plans/001-fix-flake-pattern-shortform-blindspot.md` — **new**
  (the plan that guided this work)

Changes:

- Replace single AWK `match()` with two separate patterns: one for
  `key.url = "..."` (short-form), one for `key = {` (block-form).
- New fixture test with 6 cases covering both forms.
- Wire into gate runner, registry, docs.

**Important:** After this commit, the gate will FAIL on the existing
`nixpkgs-tailscale-1_96_5` input name. This is correct — the fix exposes a
real violation that Phase 5 resolves.

Validation:

```bash
bash tests/scripts/check-flake-pattern-fixture-test.sh
bash tests/scripts/run-validation-gates-fixture-test.sh
bash scripts/run-validation-gates.sh structure
# Expected: FAIL on nixpkgs-tailscale-1_96_5 (not kebab-case)
```

Diff expectation:

- check-flake-pattern.sh: ~10 lines changed (AWK block)
- check-flake-pattern-fixture-test.sh: ~90 lines (new)
- run-validation-gates.sh: 1 line added
- run-validation-gates-fixture-test.sh: 2 lines added
- check-validation-source-of-truth.sh: ~5 lines added (test-fixture case)
- shared-script-registry.tsv: 1 line added
- 005-validation-gates.md: 1 line added
- 001 plan: ~300 lines (new)

Commit target:

- `fix(validation): capture short-form flake inputs in kebab-case check`

### Phase 5: fix(tailscale): rename flake input to kebab-case

Targets:

- `flake.nix` — `nixpkgs-tailscale-1_96_5` → `nixpkgs-tailscale-1-96-5`
- `modules/features/system/tailscale.nix` — update reference
- `flake.lock` — rename key + incidental input updates

Changes:

- Rename the input key in all three files.
- The flake.lock also contains 9 independent input updates that happened since
  the last lock commit (catppuccin, flake-parts ×2, home-manager, hyprwire,
  llm-agents, paseo, xdg-desktop-portal-hyprland, zed). These are bundled
  because flake.lock is a single artifact.

Validation:

```bash
bash scripts/run-validation-gates.sh structure
# Now all gates pass — no kebab-case violations remain
nix eval path:$PWD#nixosConfigurations.predator.config.services.tailscale.package.name
# Should output "tailscale-1.96.5"
```

Diff expectation:

- flake.nix: 1 line changed
- tailscale.nix: 2 lines changed (reference + wrapping)
- flake.lock: ~60 lines changed (rename + 9 input updates)

Commit target:

- `fix(tailscale): rename flake input to kebab-case`

### Phase 6: Archive plan

Targets:

- Move `docs/for-agents/plans/001-fix-flake-pattern-shortform-blindspot.md`
  → `docs/for-agents/archive/plans/001-fix-flake-pattern-shortform-blindspot.md`
- Move `docs/for-agents/plans/002-commit-pending-changes.md`
  → `docs/for-agents/archive/plans/002-commit-pending-changes.md`

Commit target:

- `chore: archive completed execution plans`

## Risks

| Risk                                                    | Mitigation                                                                 |
| ------------------------------------------------------- | -------------------------------------------------------------------------- |
| Phase 4 leaves the gate failing between commits 4 and 5 | This is correct and expected — the gate catches a real violation           |
| flake.lock bundles rename + 9 updates in one commit     | Lockfile is a single artifact; splitting would require manual JSON surgery |
| Indentation fix might miss tab/space edge cases         | Verify with `tr -cd '\t'` count after conversion                           |

## Definition of Done

- [ ] All 14 modified + 2 new files committed in 6 logical commits
- [ ] `bash scripts/run-validation-gates.sh structure` passes after the final commit
- [ ] `nix eval` confirms tailscale package still resolves
- [ ] No tab indentation in the 4 converted files
- [ ] Plans archived
