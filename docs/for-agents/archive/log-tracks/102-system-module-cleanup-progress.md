# System Module Cleanup Progress

## Status

Completed

## Related Plan

- [102-system-module-cleanup.md](/home/higorprado/nixos/docs/for-agents/plans/102-system-module-cleanup.md)

## Baseline

- Validation gates: PASS (structure)
- Working tree: clean (only flake.lock modified)
- 3 hosts eval: all PASS

## Slices

### Phase 1 — Merge btrfs-progs into server-tools

- Added `btrfs-progs` to `packages-server-tools.nix` NixOS half
- Emptied `packages-system-tools.nix` package list (pre-deletion)
- All 3 hosts eval: PASS
- Commit: `refactor(system): merge btrfs-progs into server-tools`

### Phase 2 — Rename files + fix lambdas

- `git mv packages-server-tools.nix → server-tools.nix`
- `git mv packages-system-tools.nix → system-tools.nix`
- Updated published module names: `packages-server-tools` → `server-tools`, `packages-system-tools` → `system-tools`
- Normalized lambdas in `networking-resolved.nix` and `networking-wireguard-client.nix`: `_:` → `{ ... }`
- Commit: `refactor(system): adopt flat naming, normalize lambdas`

### Phase 3 — Delete system-tools.nix

- `git rm modules/features/system/system-tools.nix`
- All contents already merged into `server-tools.nix`
- Commit: `refactor(system): remove system-tools, merged into server-tools`

### Phase 4 — Update host imports

- Predator: `nixos.packages-system-tools` → `nixos.server-tools`
- Aurelius: `nixos.packages-server-tools` + `nixos.packages-system-tools` → `nixos.server-tools`, `homeManager.packages-server-tools` → `homeManager.server-tools`
- Cerebelo: same merge as aurelius
- All 3 hosts eval: PASS
- Commit: `refactor(hosts): update imports for system module cleanup`

### Phase 5 — Update docs

- Updated `docs/for-agents/001-repo-map.md`: single line for `server-tools.nix`
- Commit: `docs: update repo map for system module cleanup`

### Phase 6 — Final validation

- `./scripts/run-validation-gates.sh structure`: ALL PASS (173 refs)
- `./scripts/check-repo-public-safety.sh`: PASS
- `grep -rn "packages-server-tools\|packages-system-tools" modules/`: CLEAN
- `grep -rn` living docs: CLEAN
- `ls modules/features/system/`: 31 files, zero `packages-` prefixes
- `nix build --no-link` predator (NixOS + HM): PASS

## Final State

### system/ directory (31 files, was 32)

- `server-tools.nix` — `nixos.server-tools` (lsof, strace, bind, mtr, iperf3, tcpdump, btrfs-progs) + `homeManager.server-tools` (yq-go, ncdu)
- `system-tools.nix` — **deleted** (merged into server-tools)
- `packages-` prefix — **eliminated** from system/
- Lambda style — **normalized** in networking-resolved and networking-wireguard-client

### Host import changes

| Host     | Before                                                        | After                                           |
| -------- | ------------------------------------------------------------- | ----------------------------------------------- |
| predator | `nixos.packages-system-tools`                                 | `nixos.server-tools` (gains lsof, strace, etc.) |
| aurelius | `nixos.packages-server-tools` + `nixos.packages-system-tools` | `nixos.server-tools` (merged)                   |
| cerebelo | `nixos.packages-server-tools` + `nixos.packages-system-tools` | `nixos.server-tools` (merged)                   |

### What remains open

Nothing — cleanup complete.
