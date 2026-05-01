# System Module Cleanup

## Goal

Remove the legacy `packages-` prefix from two system modules, consolidate the
single-package `system-tools.nix` into `server-tools.nix`, and bring naming
consistency to the `system/` category — matching the flat convention already
applied to `dev/`, `shell/`, `desktop/`.

## Scope

In scope:

- Rename `packages-server-tools.nix` → `server-tools.nix`
  - Update published module names: `nixos.packages-server-tools` → `nixos.server-tools`, `homeManager.packages-server-tools` → `homeManager.server-tools`
- Rename `packages-system-tools.nix` → `system-tools.nix`
  - Update published module name: `nixos.packages-system-tools` → `nixos.system-tools`
- Merge `btrfs-progs` from `system-tools.nix` into `server-tools.nix` NixOS half, then delete `system-tools.nix`
- Update host imports in `predator.nix`, `aurelius.nix`, `cerebelo.nix`
- Update `docs/for-agents/001-repo-map.md`
- Fix lambda style in `networking-resolved.nix` and `networking-wireguard-client.nix` (cosmetic, same commit)

Out of scope:

- Renaming `server-tools` to a more descriptive name (e.g., `admin-tools`)
- Reorganizing other categories (`shell/`, `desktop/`)
- Adding or removing any packages beyond the `btrfs-progs` relocation
- Changing any NixOS or HM configuration behavior
- Touching `aurelius-*` or `networking-*` sub-namespaces (they are valid)

## Current State

### Files to change

| File                        | Published as                                                        | Issue                                      |
| --------------------------- | ------------------------------------------------------------------- | ------------------------------------------ |
| `packages-server-tools.nix` | `nixos.packages-server-tools` + `homeManager.packages-server-tools` | Legacy `packages-` prefix                  |
| `packages-system-tools.nix` | `nixos.packages-system-tools`                                       | Legacy `packages-` prefix + only 1 package |

### Content of `packages-server-tools.nix`

NixOS half: `lsof`, `strace`, `bind`, `mtr`, `iperf3`, `tcpdump`
HM half: `yq-go`, `ncdu`

### Content of `packages-system-tools.nix`

NixOS only: `btrfs-progs` (single package)

### Host usage

| Host     | Imports                                                                                           |
| -------- | ------------------------------------------------------------------------------------------------- |
| predator | `nixos.packages-system-tools`                                                                     |
| aurelius | `nixos.packages-server-tools`, `nixos.packages-system-tools`, `homeManager.packages-server-tools` |
| cerebelo | `nixos.packages-server-tools`, `nixos.packages-system-tools`, `homeManager.packages-server-tools` |

### Lambda style inconsistency

- `networking-resolved.nix`: outer lambda uses `_:` (anonymous)
- `networking-wireguard-client.nix`: outer lambda uses `_:` (anonymous)
- All other system files: outer lambda uses `{ ... }` (named)

## Desired End State

### Files after cleanup

| File                            | Published as                                      | Contents                                                                                   |
| ------------------------------- | ------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| `server-tools.nix`              | `nixos.server-tools` + `homeManager.server-tools` | NixOS: lsof, strace, bind, mtr, iperf3, tcpdump, **btrfs-progs** (merged). HM: yq-go, ncdu |
| ~~`packages-system-tools.nix`~~ | —                                                 | **Deleted** (contents merged into `server-tools.nix`)                                      |

### Host imports after change

| Host     | Old                                                                                               | New                                                                     |
| -------- | ------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| predator | `nixos.packages-system-tools`                                                                     | `nixos.server-tools` (gains btrfs-progs + other tools via server-tools) |
| aurelius | `nixos.packages-server-tools`, `nixos.packages-system-tools`, `homeManager.packages-server-tools` | `nixos.server-tools`, `homeManager.server-tools`                        |
| cerebelo | `nixos.packages-server-tools`, `nixos.packages-system-tools`, `homeManager.packages-server-tools` | `nixos.server-tools`, `homeManager.server-tools`                        |

Note: predator currently imports `nixos.packages-system-tools` (btrfs-progs only) but NOT `nixos.packages-server-tools`. After merging, predator will get `nixos.server-tools` which includes both btrfs-progs AND lsof/strace/etc. This is an intentional improvement — predator is a desktop workstation that benefits from diagnostic tools.

### Lambda style normalized

- `networking-resolved.nix`: `_:` → `{ ... }`
- `networking-wireguard-client.nix`: `_:` → `{ ... }`

## Phases

### Phase 0: Baseline

Validation:

- `./scripts/run-validation-gates.sh structure`
- `nix eval` all 3 hosts
- `git status` — confirm clean working tree (only flake.lock modified)

### Phase 1: Merge `btrfs-progs` into `packages-server-tools.nix`

Targets:

- `modules/features/system/packages-server-tools.nix`
- `modules/features/system/packages-system-tools.nix`

Changes:

- Add `btrfs-progs` to the NixOS `environment.systemPackages` in `packages-server-tools.nix`
- Remove `btrfs-progs` from `packages-system-tools.nix` (file becomes empty — pre-deletion)

Validation:

- `nix eval path:$PWD#nixosConfigurations.predator.config.system.build.toplevel.drvPath`
- `nix eval` aurelius, cerebelo
- Confirm `btrfs-progs` is reachable via `packages-server-tools` on all hosts that will import it

Commit target:

- `refactor(system): merge btrfs-progs into server-tools`

### Phase 2: Rename files for flat naming + fix lambdas

Targets (git mv):

- `packages-server-tools.nix` → `server-tools.nix`
- `packages-system-tools.nix` → `system-tools.nix` (temporary — deleted in Phase 3)

Internal changes in renamed files:

- `server-tools.nix`: update `flake.modules.nixos.packages-server-tools` → `flake.modules.nixos.server-tools` and `flake.modules.homeManager.packages-server-tools` → `flake.modules.homeManager.server-tools`
- `system-tools.nix`: update `flake.modules.nixos.packages-system-tools` → `flake.modules.nixos.system-tools`

Lambda fixes:

- `networking-resolved.nix`: `_:` → `{ ... }` for outer lambda
- `networking-wireguard-client.nix`: `_:` → `{ ... }` for outer lambda

Validation:

- `git status` — confirm renames tracked
- Verify published names match filenames
- `nix eval` predator (auto-import picks up renames)

Commit target:

- `refactor(system): adopt flat naming for server-tools and system-tools`

### Phase 3: Delete `system-tools.nix` (now redundant)

Targets:

- DELETE: `modules/features/system/system-tools.nix`

Changes:

- `git rm modules/features/system/system-tools.nix`
- The content (`btrfs-progs`) already lives in `server-tools.nix` from Phase 1

Validation:

- `./scripts/run-validation-gates.sh structure`
- `grep -rn "system-tools" modules/` — must return nothing (hosts updated in next phase)

Commit target:

- `refactor(system): remove system-tools, merged into server-tools`

### Phase 4: Update host import lists

Targets:

- `modules/hosts/predator.nix`
- `modules/hosts/aurelius.nix`
- `modules/hosts/cerebelo.nix`

Changes (predator):

```diff
-  nixos.packages-system-tools
+  nixos.server-tools
```

Changes (aurelius):

```diff
-  nixos.packages-server-tools
-  nixos.packages-system-tools
+  nixos.server-tools
```

```diff
-  homeManager.packages-server-tools
+  homeManager.server-tools
```

Changes (cerebelo):

```diff
-  nixos.packages-server-tools
-  nixos.packages-system-tools
+  nixos.server-tools
```

```diff
-  homeManager.packages-server-tools
+  homeManager.server-tools
```

Validation:

- `nix eval` all 3 hosts
- Predator now imports `nixos.server-tools` (new dependency — gains lsof, strace, etc.)
- Aurelius and cerebelo merge two nixos imports into one

Commit target:

- `refactor(hosts): update imports for system module cleanup`

### Phase 5: Update docs

Targets:

- `docs/for-agents/001-repo-map.md`

Changes:

```diff
-- `system/packages-system-tools.nix`, `system/packages-server-tools.nix`
+- `system/server-tools.nix` — server and system admin tools (lsof, strace, btrfs-progs, etc.)
```

Validation:

- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-repo-public-safety.sh`

Commit target:

- `docs: update repo map for system module cleanup`

### Phase 6: Final validation

Validation:

- `./scripts/run-validation-gates.sh structure`
- `./scripts/check-repo-public-safety.sh`
- `nix eval` all 3 hosts
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.system.build.toplevel`
- `nix build --no-link path:$PWD#nixosConfigurations.predator.config.home-manager.users.higorprado.home.path`
- `grep -rn "packages-server-tools\|packages-system-tools" modules/` — must return nothing
- `ls modules/features/system/` — 30 files (down from 32, server-tools.nix present, no system-tools.nix, no packages-\* prefix)
- `grep -rn "packages-server-tools\|packages-system-tools" docs/for-agents/001-repo-map.md` — must return nothing

## Risks

- **Predator gains new packages**: Previously predator only imported `nixos.packages-system-tools` (btrfs-progs). After the merge, it imports `nixos.server-tools` which adds `lsof`, `strace`, `bind`, `mtr`, `iperf3`, `tcpdump` to its `environment.systemPackages`. These are all diagnostic/admin tools — appropriate for a desktop workstation. The NixOS `environment.systemPackages` are lightweight CLI tools, not daemons or services. No functional regression.
- **`system-tools.nix` naming collision**: The new name `system-tools.nix` exists only temporarily during Phase 2 (before deletion in Phase 3). No conflict because git mv handles it atomically.
- **Auto-import visibility**: All git mv operations must be staged before eval (Lesson 22).

## Definition of Done

- [ ] `packages-server-tools.nix` renamed to `server-tools.nix` with updated published names
- [ ] `packages-system-tools.nix` renamed to `system-tools.nix` then deleted
- [ ] `btrfs-progs` merged into `server-tools.nix` NixOS half
- [ ] `networking-resolved.nix` and `networking-wireguard-client.nix` lambdas normalized
- [ ] All 3 host files updated
- [ ] `docs/for-agents/001-repo-map.md` updated
- [ ] `nix eval` all 3 hosts passes
- [ ] `nix build --no-link` predator (NixOS + HM) passes
- [ ] `./scripts/run-validation-gates.sh structure` passes
- [ ] `./scripts/check-repo-public-safety.sh` passes
- [ ] No stale references to `packages-server-tools` or `packages-system-tools` in `modules/` or living docs
- [ ] `modules/features/system/` contains 30 files, all with consistent naming
