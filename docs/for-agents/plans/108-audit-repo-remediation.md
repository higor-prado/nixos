# Remediate Findings from Repo Audit

## Goal

Fix the top-5 actionable issues identified in `docs/for-agents/archive/reports/001-audit-report.md` (or equivalent audit run), eliminating fragile overrides, dead references, deprecated patterns, and orphaned data files.

## Scope

In scope:
- Replace `mkForce` with `mkOverride 900` for `trusted-users` in `nix-settings.nix`
- Fix dead directory reference `docs/for-agents/historical` in `report-maintainability-kpis.sh`
- Replace deprecated `buildInputs` with `nativeBuildInputs` in `devenv.nix`
- Delete orphaned `warnings-allowlist.txt` and `user-units-coverage-allowlist.txt`
- Add `trap` cleanup to cerebelo one-shot scripts (`check-sd-boot.sh`, `fix-cerebelo-nvme.sh`, `flash-cerebelo-sd.sh`)

Out of scope:
- Refactoring `with pkgs;` anti-pattern (22 occurrences — style cleanup, separate plan)
- Fixing Portuguese comments in `fix-cerebelo-nvme.sh` (cosmetic)
- Removing unused variable in `check-runtime-smoke.sh`
- Adding temp cleanup to `check-repo-public-safety.sh`
- Refactoring cerebelo scripts to use `common.sh` conventions

## Current State

### P1: `mkForce` on trusted-users

`modules/features/core/nix-settings.nix:14`:
```nix
trusted-users = lib.mkForce ([ "root" ] ++ [ config.username ]);
```
This completely replaces the NixOS default `trusted-users` list. Downstream modules (e.g., `attic-server`, `forgejo`) that add service users via `nix.settings.trusted-users` will be silently dropped because `mkForce` takes priority 50.

### P2: Dead directory reference

`scripts/report-maintainability-kpis.sh:134`:
```bash
for_agents_historical_count="$(count_markdown_files docs/for-agents/historical)"
```
Directory `docs/for-agents/historical/` does not exist. `count_markdown_files` silently returns 0 for missing directories, producing `for_agents_historical_docs=0` — misleading because it implies zero historical docs rather than "directory does not exist."

### P3: Deprecated `buildInputs`

`modules/features/dev/devenv.nix:106`:
```nix
pkgs.runCommand "devenv-direnvrc" { buildInputs = [ pkgs.devenv ]; } ''
```
`buildInputs` is the legacy `stdenv` attribute. `nativeBuildInputs` is the cross-compilation-safe equivalent. `devenv` is a native tool, so the semantic intent matches `nativeBuildInputs`.

### P4: Orphaned allowlist files

- `scripts/warnings-allowlist.txt` — 3 lines, contains `xorg\.libxcb.*renamed to 'libxcb'` regex. Never read by any `.sh` file in the entire `scripts/` tree.
- `scripts/user-units-coverage-allowlist.txt` — 18 lines, lists 12 unit names. Never read by any `.sh` file.

Both appear to be leftovers from checks that were removed or never fully implemented.

### P5: No trap cleanup in cerebelo scripts

Three scripts mount filesystems without cleanup on error/interrupt:

| Script | Mount | Issue |
|--------|-------|-------|
| `check-sd-boot.sh` | `/tmp/sd-boot` | No `trap umount` |
| `fix-cerebelo-nvme.sh` | `/tmp/nvme-root` | No `trap umount` |
| `flash-cerebelo-sd.sh` | (writes to device) | No validation that `$IMAGE` exists before `zstdcat` |

## Desired End State

- `nix-settings.nix:14` uses `lib.mkOverride 900`, allowing downstream module additions to trusted-users
- `report-maintainability-kpis.sh:134` correctly reports the archive docs count instead of referencing a nonexistent directory
- `devenv.nix:106` uses `nativeBuildInputs`
- `scripts/warnings-allowlist.txt` and `scripts/user-units-coverage-allowlist.txt` are deleted from the repo
- Cerebelo scripts have `trap` cleanup (umount on exit + interrupt) and existence validation where appropriate

## Phases

### Phase 0: Baseline

Validation:
- `./scripts/run-validation-gates.sh structure` — must pass
- `git status` — confirm clean working tree

### Phase 1: Fix fragile mkForce (P1)

Targets:
- `modules/features/core/nix-settings.nix`

Changes:
- Line 14: `lib.mkForce` → `lib.mkOverride 900`

```diff
- trusted-users = lib.mkForce ([ "root" ] ++ [ config.username ]);
+ trusted-users = lib.mkOverride 900 ([ "root" ] ++ [ config.username ]);
```

Note: `mkDefault` is priority 1000, so this still wins over defaults. Downstream modules (priority 100-999) can append.

Validation:
- `nix eval path:$PWD#nixosConfigurations.predator.config.nix.settings.trusted-users` — returns `["root", "higorprado"]`
- `./scripts/run-validation-gates.sh structure` — passes

Diff expectation:
- `trusted-users` eval output unchanged (same concrete list)

Commit target:
- `fix(core): use mkOverride 900 for trusted-users to allow downstream module additions`

### Phase 2: Fix dead directory reference (P2)

Targets:
- `scripts/report-maintainability-kpis.sh`

Changes:
- Line 134: replace `docs/for-agents/historical` → `docs/for-agents/archive`

```diff
- for_agents_historical_count="$(count_markdown_files docs/for-agents/historical)"
+ for_agents_archived_count="$(count_markdown_files docs/for-agents/archive)"
```
- Line 139: update output variable name `for_agents_historical_docs` → `for_agents_archived_docs`

Validation:
- `bash -n scripts/report-maintainability-kpis.sh` — valid syntax
- `ls docs/for-agents/archive/` — verify the directory exists (confirmed: archive/plans/, archive/log-tracks/, archive/reports/)
- `grep "historical" scripts/report-maintainability-kpis.sh` — zero matches after fix

Diff expectation:
- Output now shows actual archive doc count instead of 0

Commit target:
- `fix(reports): replace dead historical dir reference with archive count`

### Phase 3: Replace deprecated buildInputs (P3)

Targets:
- `modules/features/dev/devenv.nix`

Changes:
- Line 106: `buildInputs` → `nativeBuildInputs`

```diff
- pkgs.runCommand "devenv-direnvrc" { buildInputs = [ pkgs.devenv ]; } ''
+ pkgs.runCommand "devenv-direnvrc" { nativeBuildInputs = [ pkgs.devenv ]; } ''
```

Validation:
- `nix eval path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.xdg.configFile.direnv/direnvrc.source.outPath` — returns valid store path
- `./scripts/run-validation-gates.sh predator` — build succeeds

Commit target:
- `fix(devenv): use nativeBuildInputs instead of deprecated buildInputs`

### Phase 4: Delete orphaned allowlist files (P4)

Targets:
- `scripts/warnings-allowlist.txt`
- `scripts/user-units-coverage-allowlist.txt`

Changes:
- `git rm scripts/warnings-allowlist.txt`
- `git rm scripts/user-units-coverage-allowlist.txt`

Validation:
- `git status` — confirms 2 deletions staged
- `grep -r "warnings-allowlist\|user-units-coverage-allowlist" scripts/` — zero references remain
- `grep -r "warnings-allowlist\|user-units-coverage-allowlist" docs/` — zero references, or only historical/archive mentions (acceptable)
- `./scripts/run-validation-gates.sh structure` — passes
- `./scripts/check-docs-drift.sh` — passes (no living doc should reference these files)

Commit target:
- `chore(scripts): remove orphaned allowlist data files`

### Phase 5: Add trap cleanup to cerebelo scripts (P5)

Targets:
- `scripts/check-sd-boot.sh`
- `scripts/fix-cerebelo-nvme.sh`
- `scripts/flash-cerebelo-sd.sh`

Changes for `check-sd-boot.sh`:
```diff
 #!/usr/bin/env bash
 set -euo pipefail
+trap 'sudo umount /tmp/sd-boot 2>/dev/null || true' EXIT
 
 mkdir -p /tmp/sd-boot
 sudo mount /dev/mmcblk0p1 /tmp/sd-boot
 echo "=== extlinux.conf ==="
 find /tmp/sd-boot -name "extlinux.conf" -exec cat {} \;
 sudo umount /tmp/sd-boot
```

Changes for `fix-cerebelo-nvme.sh`:
```diff
 #!/usr/bin/env bash
 set -euo pipefill
+trap 'sudo umount /tmp/nvme-root 2>/dev/null || true' EXIT
 
 # Mount NVMe root
 mkdir -p /tmp/nvme-root
 sudo mount /dev/nvme0n1p2 /tmp/nvme-root
```

Changes for `flash-cerebelo-sd.sh`:
```diff
 #!/usr/bin/env bash
 set -euo pipefail
 
 IMAGE="$HOME/Downloads/orangepi5-sd-image.img.zst"
 DEVICE="/dev/mmcblk0"
 
+if [ ! -f "$IMAGE" ]; then
+  echo "[flash] ERROR: image not found: $IMAGE" >&2
+  exit 1
+fi
+
 echo "[flash] Writing $IMAGE to $DEVICE ..."
```

Validation:
- `head -5 scripts/check-sd-boot.sh` — shows trap line after set
- `head -5 scripts/fix-cerebelo-nvme.sh` — shows trap line
- `head -10 scripts/flash-cerebelo-sd.sh` — shows image existence check
- `bash -n scripts/check-sd-boot.sh` — valid syntax
- `bash -n scripts/fix-cerebelo-nvme.sh` — valid syntax
- `bash -n scripts/flash-cerebelo-sd.sh` — valid syntax
- `./scripts/check-changed-files-quality.sh` — no shellcheck issues

Commit target:
- `fix(scripts): add trap cleanup and validation to cerebelo helpers`

### Phase 6: Final validation

Validation:
- `./scripts/run-validation-gates.sh structure` — all gates pass
- `nix eval path:$PWD#nixosConfigurations.predator.config.nix.settings.trusted-users` — returns expected values
- `git log --oneline -5` — confirms 5 commits exist (or squash as appropriate)
- `./scripts/check-changed-files-quality.sh` — clean

## Risks

- **trusted-users priority change is subtle.** `mkOverride 900` still beats defaults (1000) but allows priority 100-899 modules to append. No tracked module currently adds to `trusted-users` at the NixOS level, so behavior is unchanged. If a future module (e.g., a server service) adds trusted users at priority 500, the fix enables that — which is the desired behavior.
- **archive directory counts.** `count_markdown_files docs/for-agents/archive` will count all markdown under `archive/plans/`, `archive/log-tracks/`, and `archive/reports/` — a superset of what the old historical directory might have contained. This is strictly more accurate.
- **Cerebelo scripts are not covered by tests.** Changes are mechanical (`trap`, existence check) — no behavioral change to the non-error path.
- **No `.nix.example` referencing removed allowlists.** Verified: zero references to either allowlist file in docs or `.nix.example` files.

## Definition of Done

- [ ] `nix-settings.nix:14` uses `mkOverride 900`
- [ ] `report-maintainability-kpis.sh` correctly counts `docs/for-agents/archive/` instead of nonexistent `historical/`
- [ ] `devenv.nix:106` uses `nativeBuildInputs`
- [ ] `scripts/warnings-allowlist.txt` deleted
- [ ] `scripts/user-units-coverage-allowlist.txt` deleted
- [ ] `check-sd-boot.sh` has `trap EXIT` for umount
- [ ] `fix-cerebelo-nvme.sh` has `trap EXIT` for umount
- [ ] `flash-cerebelo-sd.sh` validates `$IMAGE` exists before flash
- [ ] `./scripts/run-validation-gates.sh structure` passes
- [ ] `./scripts/check-changed-files-quality.sh` passes
- [ ] No stale references to removed allowlist files in any tracked file
